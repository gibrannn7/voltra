<?php

namespace App\Filament\Widgets;

use App\Models\Transaction;
use Filament\Widgets\ChartWidget;

class TransactionStatsWidget extends ChartWidget
{
    protected static ?string $heading = 'Transaksi Hari Ini';

    protected static ?int $sort = 2;

    protected int | string | array $columnSpan = 1;

    protected static ?string $maxHeight = '280px';

    /**
     * Poll every 30 seconds for real-time updates.
     */
    protected static ?string $pollingInterval = '30s';

    protected function getType(): string
    {
        return 'doughnut';
    }

    protected function getData(): array
    {
        $today = now()->startOfDay();

        $success    = Transaction::where('status', Transaction::STATUS_SUCCESS)
            ->where('created_at', '>=', $today)->count();
        $failed     = Transaction::where('status', Transaction::STATUS_FAILED)
            ->where('created_at', '>=', $today)->count();
        $processing = Transaction::where('status', Transaction::STATUS_PROCESSING)
            ->where('created_at', '>=', $today)->count();
        $pending    = Transaction::where('status', Transaction::STATUS_PENDING)
            ->where('created_at', '>=', $today)->count();

        return [
            'datasets' => [
                [
                    'label' => 'Transaksi',
                    'data'  => [$success, $failed, $processing, $pending],
                    'backgroundColor' => [
                        '#10B981', // Success - Green
                        '#EF4444', // Failed - Red
                        '#F59E0B', // Processing - Orange/Warning
                        '#6B7280', // Pending - Gray
                    ],
                    'borderColor' => '#1E293B',
                    'borderWidth' => 2,
                ],
            ],
            'labels' => ['Sukses', 'Gagal', 'Processing', 'Pending'],
        ];
    }

    protected function getOptions(): array
    {
        return [
            'plugins' => [
                'legend' => [
                    'position' => 'bottom',
                    'labels' => [
                        'padding' => 16,
                        'usePointStyle' => true,
                    ],
                ],
            ],
            'cutout' => '60%',
        ];
    }
}
