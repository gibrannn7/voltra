<?php

namespace App\Services;

use App\Models\BalanceMutation;
use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WalletService
{
    /**
     * Credit (add) funds to a user's wallet.
     * Used for: Top-up, Refund, Cashback.
     *
     * @param  User    $user         The wallet owner
     * @param  string  $amount       Amount to credit (string for bcmath precision)
     * @param  string  $description  Reason for credit
     * @param  int|null $referenceId Associated transaction ID
     * @return array{success: bool, message: string, balance?: string}
     */
    public function credit(User $user, string $amount, string $description, ?int $referenceId = null): array
    {
        if (bccomp($amount, '0', 2) <= 0) {
            return ['success' => false, 'message' => 'Amount must be greater than 0'];
        }

        try {
            return DB::transaction(function () use ($user, $amount, $description, $referenceId) {
                // Lock the wallet row for update to prevent race conditions
                $wallet = Wallet::where('user_id', $user->id)->lockForUpdate()->first();

                if (! $wallet) {
                    $wallet = Wallet::create([
                        'user_id' => $user->id,
                        'balance' => '0.00',
                    ]);
                    $wallet = $wallet->fresh();
                    $wallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();
                }

                if ($wallet->is_blocked) {
                    return ['success' => false, 'message' => 'Wallet is blocked. Please contact Customer Service.'];
                }

                // Use bcadd for precision
                $newBalance = bcadd($wallet->balance, $amount, 2);
                $wallet->update(['balance' => $newBalance]);

                // Record the mutation
                BalanceMutation::create([
                    'user_id'      => $user->id,
                    'type'         => BalanceMutation::TYPE_CREDIT,
                    'amount'       => $amount,
                    'description'  => $description,
                    'reference_id' => $referenceId,
                ]);

                return [
                    'success' => true,
                    'message' => 'Funds credited successfully',
                    'balance' => $newBalance,
                ];
            });
        } catch (\Throwable $e) {
            Log::error('WalletService credit failed', [
                'user_id' => $user->id,
                'amount'  => $amount,
                'error'   => $e->getMessage(),
            ]);

            return ['success' => false, 'message' => 'Failed to credit wallet'];
        }
    }

    /**
     * Debit (subtract) funds from a user's wallet.
     * Used for: Purchases via wallet balance.
     *
     * @param  User    $user         The wallet owner
     * @param  string  $amount       Amount to debit (string for bcmath precision)
     * @param  string  $description  Reason for debit
     * @param  int|null $referenceId Associated transaction ID
     * @return array{success: bool, message: string, balance?: string}
     */
    public function debit(User $user, string $amount, string $description, ?int $referenceId = null): array
    {
        if (bccomp($amount, '0', 2) <= 0) {
            return ['success' => false, 'message' => 'Amount must be greater than 0'];
        }

        try {
            return DB::transaction(function () use ($user, $amount, $description, $referenceId) {
                $wallet = Wallet::where('user_id', $user->id)->lockForUpdate()->first();

                if (! $wallet) {
                    return ['success' => false, 'message' => 'Wallet not found'];
                }

                if ($wallet->is_blocked) {
                    return ['success' => false, 'message' => 'Wallet is blocked. Please contact Customer Service.'];
                }

                // Check sufficient balance using bccomp
                if (bccomp($wallet->balance, $amount, 2) < 0) {
                    return ['success' => false, 'message' => 'Saldo tidak mencukupi'];
                }

                $newBalance = bcsub($wallet->balance, $amount, 2);
                $wallet->update(['balance' => $newBalance]);

                BalanceMutation::create([
                    'user_id'      => $user->id,
                    'type'         => BalanceMutation::TYPE_DEBIT,
                    'amount'       => $amount,
                    'description'  => $description,
                    'reference_id' => $referenceId,
                ]);

                return [
                    'success' => true,
                    'message' => 'Funds debited successfully',
                    'balance' => $newBalance,
                ];
            });
        } catch (\Throwable $e) {
            Log::error('WalletService debit failed', [
                'user_id' => $user->id,
                'amount'  => $amount,
                'error'   => $e->getMessage(),
            ]);

            return ['success' => false, 'message' => 'Failed to debit wallet'];
        }
    }

    /**
     * Execute the Automated Refund Protocol.
     *
     * When Midtrans settlement succeeded but Digiflazz purchase failed:
     * 1. Credit the total_amount back to user's wallet
     * 2. Record it as a balance_mutation (credit)
     * 3. Update transaction status to 'failed'
     *
     * ALL wrapped in DB::transaction with savepoints to prevent double-spending.
     *
     * @param  Transaction  $transaction  The failed transaction to refund
     * @return array{success: bool, message: string}
     */
    public function refund(Transaction $transaction): array
    {
        // Guard: only refund if not already refunded
        if ($transaction->isFailed()) {
            // Check if a refund mutation already exists
            $existingRefund = BalanceMutation::where('reference_id', $transaction->id)
                ->where('type', BalanceMutation::TYPE_CREDIT)
                ->where('description', 'like', '%refund%')
                ->exists();

            if ($existingRefund) {
                return ['success' => false, 'message' => 'Refund already processed'];
            }
        }

        try {
            return DB::transaction(function () use ($transaction) {
                $user = $transaction->user;

                // Lock the wallet
                $wallet = Wallet::where('user_id', $user->id)->lockForUpdate()->first();

                if (! $wallet) {
                    return ['success' => false, 'message' => 'User wallet not found'];
                }

                // Credit the refund amount
                $refundAmount = $transaction->total_amount;
                $newBalance   = bcadd($wallet->balance, $refundAmount, 2);
                $wallet->update(['balance' => $newBalance]);

                // Record the refund mutation
                BalanceMutation::create([
                    'user_id'      => $user->id,
                    'type'         => BalanceMutation::TYPE_CREDIT,
                    'amount'       => $refundAmount,
                    'description'  => "Automated refund for failed transaction #{$transaction->id}",
                    'reference_id' => $transaction->id,
                ]);

                // Update transaction status
                $transaction->update(['status' => Transaction::STATUS_FAILED]);

                Log::info('Automated refund processed', [
                    'transaction_id' => $transaction->id,
                    'user_id'        => $user->id,
                    'amount'         => $refundAmount,
                    'new_balance'    => $newBalance,
                ]);

                return [
                    'success' => true,
                    'message' => 'Refund processed successfully',
                ];
            });
        } catch (\Throwable $e) {
            Log::critical('Automated refund FAILED - MANUAL INTERVENTION REQUIRED', [
                'transaction_id' => $transaction->id,
                'error'          => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'message' => 'Refund processing failed. Manual intervention required.',
            ];
        }
    }

    /**
     * Get the current wallet balance for a user.
     */
    public function getBalance(User $user): string
    {
        $wallet = $user->wallet;
        return $wallet ? $wallet->balance : '0.00';
    }
}
