<?php

namespace App\Jobs;

use App\Models\Transaction;
use App\Services\DigiflazzService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessMidtransSettlement implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    public function __construct(
        private string $orderId,
        private array $payload,
    ) {}

    /**
     * Process Midtrans settlement:
     * 1. Find the transaction by midtrans_order_id
     * 2. Update status to 'processing'
     * 3. Hit Digiflazz purchase API
     * 4. All within DB::transaction to prevent race conditions
     */
    public function handle(DigiflazzService $digiflazzService): void
    {
        Log::info('ProcessMidtransSettlement: Start', ['order_id' => $this->orderId]);

        try {
            DB::transaction(function () use ($digiflazzService) {
                // Lock the transaction row to prevent duplicate processing
                $transaction = Transaction::where('midtrans_order_id', $this->orderId)
                    ->lockForUpdate()
                    ->first();

                if (! $transaction) {
                    Log::error('ProcessMidtransSettlement: Transaction not found', [
                        'order_id' => $this->orderId,
                    ]);
                    return;
                }

                // Guard: only process if still pending
                if (! $transaction->isPending()) {
                    Log::info('ProcessMidtransSettlement: Transaction already processed', [
                        'order_id' => $this->orderId,
                        'status'   => $transaction->status,
                    ]);
                    return;
                }

                // Update to processing
                $transaction->update(['status' => Transaction::STATUS_PROCESSING]);
            });

            // After the DB lock is released, hit Digiflazz
            $transaction = Transaction::where('midtrans_order_id', $this->orderId)->first();

            if (! $transaction || ! $transaction->isProcessing()) {
                return;
            }

            $product = $transaction->product;

            if (! $product) {
                Log::error('ProcessMidtransSettlement: Product not found', [
                    'transaction_id' => $transaction->id,
                ]);
                return;
            }

            $result = $digiflazzService->purchase(
                $product->sku_code,
                $transaction->customer_number,
                $transaction->digiflazz_ref_id
            );

            if ($result['success']) {
                $transaction->update([
                    'status'   => Transaction::STATUS_SUCCESS,
                    'sn_token' => $result['sn'],
                ]);

                // Dispatch FCM notification
                SendFcmNotification::dispatch(
                    $transaction->user_id,
                    'Transaksi Berhasil!',
                    "Pembelian {$product->name} berhasil. Token: {$result['sn']}",
                    'transaction'
                );

                Log::info('ProcessMidtransSettlement: Purchase success', [
                    'transaction_id' => $transaction->id,
                    'sn'             => $result['sn'],
                ]);
            } elseif ($result['pending']) {
                // Still pending — will be resolved by Digiflazz webhook
                Log::info('ProcessMidtransSettlement: Purchase pending at Digiflazz', [
                    'transaction_id' => $transaction->id,
                ]);
            } else {
                // Purchase failed — the Digiflazz webhook callback will handle the refund
                Log::warning('ProcessMidtransSettlement: Purchase failed', [
                    'transaction_id' => $transaction->id,
                    'message'        => $result['message'],
                ]);
            }
        } catch (\Throwable $e) {
            Log::error('ProcessMidtransSettlement: Exception', [
                'order_id' => $this->orderId,
                'error'    => $e->getMessage(),
            ]);

            throw $e; // Re-throw to trigger retry
        }
    }
}
