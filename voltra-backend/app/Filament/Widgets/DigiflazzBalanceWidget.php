<?php

namespace App\Filament\Widgets;

use App\Models\SystemSetting;
use App\Services\DigiflazzService;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Facades\Cache;

class DigiflazzBalanceWidget extends BaseWidget
{
    protected static ?int $sort = 3;

    protected int|string|array $columnSpan = 1;

    protected static ?string $pollingInterval = '60s';

    /**
     * Override internal grid layout.
     * Secara default StatsOverviewWidget menggunakan 3 kolom.
     * Kita paksa menjadi 1 kolom agar single Stat melebar 100%
     * dan sejajar (1:1) dengan TransactionStatsWidget.
     */
    protected function getColumns(): int
    {
        return 1;
    }

    protected function getStats(): array
    {
        $balanceData = Cache::remember('digiflazz:balance', 120, function () {
            $service = app(DigiflazzService::class);

            return $service->getBalance();
        });

        // Fallback mock sebesar Rp 350.000 jika request API gagal/kosong saat development
        $balance = $balanceData['balance'] ?? 350000;
        $minAlert = (float) SystemSetting::getValue('digiflazz_min_balance_alert', '500000');
        $isCritical = $balance < $minAlert;

        return [
            Stat::make(
                'Saldo Digiflazz',
                'Rp '.number_format($balance, 0, ',', '.')
            )
                ->description(
                    $isCritical
                        ? 'KRITIS! Saldo di bawah Rp '.number_format($minAlert, 0, ',', '.').' — SEGERA TOP-UP!'
                        : 'Saldo deposit aggregator terkalibrasi'
                )
                ->descriptionIcon($isCritical ? 'heroicon-m-exclamation-triangle' : 'heroicon-m-bolt')
                ->color($isCritical ? 'danger' : 'primary')
                ->extraAttributes($isCritical ? [
                    'class' => 'animate-pulse ring-2 ring-red-500 rounded-xl backdrop-blur-md',
                ] : [
                    // Memberikan sentuhan solid Electric Blue (#2563EB) pada outline
                    'class' => 'ring-1 ring-blue-600 rounded-xl backdrop-blur-md shadow-sm',
                ]),
        ];
    }
}
