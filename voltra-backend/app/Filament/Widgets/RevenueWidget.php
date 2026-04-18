<?php

namespace App\Filament\Widgets;

use App\Models\Transaction;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class RevenueWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected int|string|array $columnSpan = 'full';

    /**
     * Poll every 30 seconds for real-time updates.
     */
    protected static ?string $pollingInterval = '30s';

    protected function getStats(): array
    {
        $today = now()->startOfDay();

        // Total Revenue Today
        $revenueToday = Transaction::where('status', Transaction::STATUS_SUCCESS)
            ->where('created_at', '>=', $today)
            ->sum('total_amount');

        // Total Profit Today
        $profitToday = Transaction::where('status', Transaction::STATUS_SUCCESS)
            ->where('created_at', '>=', $today)
            ->sum('profit_margin');

        // Successful Transactions Today
        $successToday = Transaction::where('status', Transaction::STATUS_SUCCESS)
            ->where('created_at', '>=', $today)
            ->count();

        // Failed Transactions Today
        $failedToday = Transaction::where('status', Transaction::STATUS_FAILED)
            ->where('created_at', '>=', $today)
            ->count();

        // Pending Transactions
        $pendingNow = Transaction::whereIn('status', [
            Transaction::STATUS_PENDING,
            Transaction::STATUS_PROCESSING,
        ])->count();

        // Revenue this month
        $revenueMonth = Transaction::where('status', Transaction::STATUS_SUCCESS)
            ->where('created_at', '>=', now()->startOfMonth())
            ->sum('total_amount');

        return [
            Stat::make('Revenue Hari Ini', 'Rp '.number_format((float) $revenueToday, 0, ',', '.'))
                ->description('Total transaksi sukses hari ini')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success')
                ->chart([7, 3, 4, 5, 6, 3, 5, 3]),

            Stat::make('Profit Hari Ini', 'Rp '.number_format((float) $profitToday, 0, ',', '.'))
                ->description('Margin dari admin markup')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('success'),

            Stat::make('Transaksi Sukses', (string) $successToday)
                ->description('Hari ini')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),

            Stat::make('Transaksi Gagal', (string) $failedToday)
                ->description('Hari ini')
                ->descriptionIcon('heroicon-m-x-circle')
                ->color($failedToday > 0 ? 'danger' : 'gray'),

            Stat::make('Pending/Processing', (string) $pendingNow)
                ->description('Belum selesai')
                ->descriptionIcon('heroicon-m-clock')
                ->color($pendingNow > 0 ? 'warning' : 'gray'),

            Stat::make('Revenue Bulan Ini', 'Rp '.number_format((float) $revenueMonth, 0, ',', '.'))
                ->description(now()->format('F Y'))
                ->descriptionIcon('heroicon-m-calendar')
                ->color('info'),
        ];
    }
}
