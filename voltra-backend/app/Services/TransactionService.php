<?php

namespace App\Services;

use App\Models\Product;
use App\Models\Promo;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class TransactionService
{
    public function __construct(
        private MidtransService $midtransService,
        private DigiflazzService $digiflazzService,
        private WalletService $walletService,
    ) {}

    /**
     * Create a new transaction.
     *
     * Orchestrates: validate -> create record -> initiate payment.
     * Implements idempotency key check to prevent duplicate charges.
     *
     * @param  User    $user
     * @param  Product $product
     * @param  string  $customerNumber   PLN meter / phone number
     * @param  string  $paymentMethod    'wallet' or Midtrans payment type
     * @param  string|null $promoCode    Optional promo code
     * @param  string|null $idempotencyKey Client-generated idempotency key
     * @param  string|null $customerName  From inquiry response
     * @return array
     */
    public function createTransaction(
        User $user,
        Product $product,
        string $customerNumber,
        string $paymentMethod,
        ?string $promoCode = null,
        ?string $idempotencyKey = null,
        ?string $customerName = null,
    ): array {
        // ─── 1. Idempotency Check ─────────────────────────
        if ($idempotencyKey) {
            $existing = Transaction::where('idempotency_key', $idempotencyKey)->first();
            if ($existing) {
                return [
                    'success'     => true,
                    'message'     => 'Transaction already exists (idempotent)',
                    'transaction' => $existing,
                    'duplicate'   => true,
                ];
            }
        }

        // ─── 2. Validate Product ──────────────────────────
        if (! $product->is_active) {
            return ['success' => false, 'message' => 'Product is currently unavailable'];
        }

        // ─── 3. Calculate Pricing ─────────────────────────
        $basePrice  = $product->base_price;
        $adminFee   = $product->admin_markup;
        $discount   = '0.00';
        $promoId    = null;

        // Validate and apply promo
        if ($promoCode) {
            $promo = Promo::where('promo_code', $promoCode)->valid()->first();

            if ($promo) {
                $subtotal = bcadd($basePrice, $adminFee, 2);
                if ($promo->isValidForAmount($subtotal)) {
                    $discount = $promo->discount_amount;
                    $promoId  = $promo->id;
                }
            }
        }

        // Determine PG fee (wallet = 0, otherwise estimate)
        $pgFee = $paymentMethod === 'wallet' ? '0.00' : '0.00'; // PG fee comes from Midtrans

        // Calculate total: base_price + admin_fee - discount + pg_fee
        $subtotal    = bcadd($basePrice, $adminFee, 2);
        $afterDiscount = bcsub($subtotal, $discount, 2);
        $totalAmount = bcadd($afterDiscount, $pgFee, 2);

        // Calculate profit margin: admin_fee - discount (what Superadmin earns)
        $profitMargin = bcsub($adminFee, $discount, 2);

        // ─── 4. Generate References ───────────────────────
        $midtransOrderId = 'VLT-' . now()->format('YmdHis') . '-' . Str::upper(Str::random(4));
        $digiflazzRefId  = 'DGF-' . now()->format('YmdHis') . '-' . Str::upper(Str::random(4));

        try {
            return DB::transaction(function () use (
                $user, $product, $customerNumber, $customerName,
                $paymentMethod, $basePrice, $adminFee, $discount,
                $pgFee, $totalAmount, $profitMargin, $promoId,
                $midtransOrderId, $digiflazzRefId, $idempotencyKey,
            ) {
                // ─── 5. Create Transaction Record ─────────
                $transaction = Transaction::create([
                    'user_id'           => $user->id,
                    'product_id'        => $product->id,
                    'promo_id'          => $promoId,
                    'customer_number'   => $customerNumber,
                    'customer_name'     => $customerName,
                    'base_price'        => $basePrice,
                    'admin_fee'         => $adminFee,
                    'discount'          => $discount,
                    'pg_fee'            => $pgFee,
                    'total_amount'      => $totalAmount,
                    'profit_margin'     => $profitMargin,
                    'status'            => Transaction::STATUS_PENDING,
                    'payment_method'    => $paymentMethod,
                    'midtrans_order_id' => $midtransOrderId,
                    'digiflazz_ref_id'  => $digiflazzRefId,
                    'idempotency_key'   => $idempotencyKey,
                ]);

                // ─── 6. Increment Promo Usage ─────────────
                if ($promoId) {
                    Promo::where('id', $promoId)->increment('current_usage');
                }

                // ─── 7. Process Payment ───────────────────
                if ($paymentMethod === 'wallet') {
                    return $this->processWalletPayment($user, $transaction, $product);
                }

                // For Midtrans: create Snap transaction
                return $this->processMidtransPayment($user, $transaction);
            });
        } catch (\Throwable $e) {
            Log::error('TransactionService createTransaction failed', [
                'user_id' => $user->id,
                'error'   => $e->getMessage(),
            ]);

            return ['success' => false, 'message' => 'Gagal membuat transaksi. Silakan coba lagi.'];
        }
    }

    /**
     * Process payment via internal wallet balance.
     * Instant: debit wallet -> hit Digiflazz immediately.
     */
    private function processWalletPayment(User $user, Transaction $transaction, Product $product): array
    {
        // Debit wallet
        $debitResult = $this->walletService->debit(
            $user,
            $transaction->total_amount,
            "Purchase: {$product->name} ({$transaction->customer_number})",
            $transaction->id
        );

        if (! $debitResult['success']) {
            $transaction->update(['status' => Transaction::STATUS_FAILED]);
            return [
                'success' => false,
                'message' => $debitResult['message'],
            ];
        }

        // Update status to processing and hit Digiflazz
        $transaction->update(['status' => Transaction::STATUS_PROCESSING]);

        $purchaseResult = $this->digiflazzService->purchase(
            $product->sku_code,
            $transaction->customer_number,
            $transaction->digiflazz_ref_id
        );

        if ($purchaseResult['success']) {
            $transaction->update([
                'status'   => Transaction::STATUS_SUCCESS,
                'sn_token' => $purchaseResult['sn'],
            ]);

            return [
                'success'     => true,
                'message'     => 'Transaksi berhasil!',
                'transaction' => $transaction->fresh(),
                'sn_token'    => $purchaseResult['sn'],
            ];
        }

        if ($purchaseResult['pending']) {
            return [
                'success'     => true,
                'message'     => 'Transaksi sedang diproses',
                'transaction' => $transaction->fresh(),
                'pending'     => true,
            ];
        }

        // Purchase failed — execute automated refund
        $this->walletService->refund($transaction);

        return [
            'success' => false,
            'message' => 'Transaksi gagal. Dana telah dikembalikan ke saldo Voltra Anda.',
            'refunded' => true,
        ];
    }

    /**
     * Process payment via Midtrans (external gateway).
     * Creates a Snap token; actual Digiflazz purchase happens after webhook settlement.
     */
    private function processMidtransPayment(User $user, Transaction $transaction): array
    {
        $snapResult = $this->midtransService->createSnapTransaction(
            $transaction->midtrans_order_id,
            $transaction->total_amount,
            [
                'name'  => $user->name,
                'email' => $user->email ?? 'user@voltra.app',
                'phone' => $user->phone_number,
            ]
        );

        if (! $snapResult['success']) {
            $transaction->update(['status' => Transaction::STATUS_FAILED]);

            return [
                'success' => false,
                'message' => $snapResult['message'],
            ];
        }

        return [
            'success'      => true,
            'message'      => 'Silakan selesaikan pembayaran',
            'transaction'  => $transaction->fresh(),
            'snap_token'   => $snapResult['snap_token'],
            'redirect_url' => $snapResult['redirect_url'],
        ];
    }
}
