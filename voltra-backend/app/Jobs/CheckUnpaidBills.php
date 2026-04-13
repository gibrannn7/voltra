<?php

namespace App\Jobs;

use App\Models\Transaction;
use App\Models\User;
use App\Services\FcmService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class CheckUnpaidBills implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Check for users who haven't paid postpaid bills (PLN Tagihan).
     *
     * Runs daily at 09:00 via scheduler.
     * Only triggers after the 20th of each month.
     */
    public function handle(FcmService $fcmService): void
    {
        $today = now();

        // Only send reminders on day >= 20
        if ($today->day < 20) {
            Log::info('CheckUnpaidBills: Skipping — not yet day 20');
            return;
        }

        $startOfMonth = $today->copy()->startOfMonth();
        $endOfMonth   = $today->copy()->endOfMonth();

        // Find users who have NOT made a postpaid PLN transaction this month
        $usersWithBillsPaid = Transaction::where('status', Transaction::STATUS_SUCCESS)
            ->whereBetween('created_at', [$startOfMonth, $endOfMonth])
            ->whereHas('product', function ($query) {
                $query->where('type', 'postpaid')
                    ->whereHas('category', function ($q) {
                        $q->where('name', 'PLN');
                    });
            })
            ->pluck('user_id')
            ->unique();

        // All active users who haven't paid
        $unpaidUsers = User::where('role', 'user')
            ->where('is_suspended', false)
            ->whereNotIn('id', $usersWithBillsPaid)
            ->whereNotNull('fcm_token')
            ->get();

        $count = 0;

        foreach ($unpaidUsers as $user) {
            $fcmService->sendToUser(
                $user,
                'Tagihan Listrik Belum Dibayar!',
                'Jangan lupa bayar tagihan listrik bulan ini sebelum terlambat. Bayar sekarang di Voltra App.',
                'reminder',
                ['type' => 'bill_reminder']
            );

            $count++;
        }

        Log::info('CheckUnpaidBills: Reminders sent', ['count' => $count, 'day' => $today->day]);
    }
}
