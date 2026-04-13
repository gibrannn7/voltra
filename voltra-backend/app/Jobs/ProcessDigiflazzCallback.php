<?php

namespace App\Jobs;

use App\Models\Transaction;
use App\Services\FcmService;
use App\Services\WalletService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessDigiflazzCallback implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 15;

    public function __construct(
        private array $callbackData,
    ) {}

    /**
     * Process Digiflazz callback:
     *
     * If status "Sukses":
     *   - Update transaction to success
     *   - Extract SN/token
     *   - Send FCM notification with token
     *
     * If status "Gagal" and Midtrans already settled:
     *   - Execute Automated Refund Protocol
     *   - Credit total_amount back to user wallet
     *   - Record in balance_mutations
     *   - Mark transaction as failed
     *   - Send FCM: "Transaksi Gagal, Dana dikembalikan ke Saldo Voltra"
     */
    public function handle(WalletService $walletService, FcmService $fcmService): void
    {
        $refId  = $this->callbackData['ref_id'] ?? null;
        $status = strtolower($this->callbackData['status'] ?? '');
        $sn     = $this->callbackData['sn'] ?? null;

        if (! $refId) {
            Log::error('ProcessDigiflazzCallback: No ref_id in callback', $this->callbackData);
            return;
        }

        Log::info('ProcessDigiflazzCallback: Start', [
            'ref_id' => $refId,
            'status' => $status,
            'sn'     => $sn,
        ]);

        try {
            DB::transaction(function () use ($refId, $status, $sn, $walletService, $fcmService) {
                $transaction = Transaction::where('digiflazz_ref_id', $refId)
                    ->lockForUpdate()
                    ->first();

                if (! $transaction) {
                    Log::error('ProcessDigiflazzCallback: Transaction not found', ['ref_id' => $refId]);
                    return;
                }

                // Guard: don't re-process already completed transactions
                if ($transaction->isSuccessful() || $transaction->isFailed()) {
                    Log::info('ProcessDigiflazzCallback: Already processed', [
                        'ref_id'   => $refId,
                        'status'   => $transaction->status,
                    ]);
                    return;
                }

                $user    = $transaction->user;
                $product = $transaction->product;

                if ($status === 'sukses') {
                    // ─── SUCCESS FLOW ─────────────────────────
                    $transaction->update([
                        'status'   => Transaction::STATUS_SUCCESS,
                        'sn_token' => $sn,
                    ]);

                    $fcmService->sendToUser(
                        $user,
                        'Transaksi Berhasil!',
                        "Pembelian {$product->name} berhasil. " . ($sn ? "Token/SN: {$sn}" : ''),
                        'transaction',
                        [
                            'transaction_id' => $transaction->id,
                            'sn_token'       => $sn,
                            'type'           => 'transaction_success',
                        ]
                    );

                    Log::info('ProcessDigiflazzCallback: Success', [
                        'transaction_id' => $transaction->id,
                        'sn'             => $sn,
                    ]);
                } elseif ($status === 'gagal') {
                    // ─── AUTOMATED REFUND PROTOCOL ────────────
                    // Midtrans already settled (user paid) but Digiflazz purchase failed.
                    // We MUST refund the user's funds to their wallet.

                    Log::warning('ProcessDigiflazzCallback: FAILED - Initiating Automated Refund', [
                        'transaction_id' => $transaction->id,
                        'ref_id'         => $refId,
                    ]);

                    // Execute refund with full DB::transaction savepoints
                    $refundResult = $walletService->refund($transaction);

                    if ($refundResult['success']) {
                        // Send refund notification
                        $fcmService->sendToUser(
                            $user,
                            'Transaksi Gagal - Dana Dikembalikan',
                            "Pembelian {$product->name} gagal. Dana Rp " .
                                number_format((float) $transaction->total_amount, 0, ',', '.') .
                                ' telah dikembalikan ke Saldo Voltra Anda.',
                            'transaction',
                            [
                                'transaction_id' => $transaction->id,
                                'type'           => 'refund',
                                'refund_amount'  => $transaction->total_amount,
                            ]
                        );

                        Log::info('ProcessDigiflazzCallback: Refund processed', [
                            'transaction_id' => $transaction->id,
                            'amount'         => $transaction->total_amount,
                        ]);
                    } else {
                        // CRITICAL: Refund failed — requires manual intervention
                        Log::critical('ProcessDigiflazzCallback: REFUND FAILED - MANUAL INTERVENTION REQUIRED', [
                            'transaction_id' => $transaction->id,
                            'amount'         => $transaction->total_amount,
                            'error'          => $refundResult['message'],
                        ]);

                        // Still mark transaction as failed
                        $transaction->update(['status' => Transaction::STATUS_FAILED]);

                        $fcmService->sendToUser(
                            $user,
                            'Transaksi Gagal',
                            "Pembelian {$product->name} gagal. Tim kami sedang memproses pengembalian dana Anda. Hubungi CS jika diperlukan.",
                            'transaction',
                            [
                                'transaction_id' => $transaction->id,
                                'type'           => 'refund_failed',
                            ]
                        );
                    }
                }
                // 'Pending' status: no action needed, wait for next callback
            });
        } catch (\Throwable $e) {
            Log::error('ProcessDigiflazzCallback: Exception', [
                'ref_id' => $refId,
                'error'  => $e->getMessage(),
            ]);

            throw $e; // Retry
        }
    }
}
