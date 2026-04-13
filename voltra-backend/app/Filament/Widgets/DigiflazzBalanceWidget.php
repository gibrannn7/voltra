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

    protected int | string | array $columnSpan = 1;

    /**
     * Poll every 60 seconds — balance check is an external API call.
     */
    protected static ?string $pollingInterval = '60s';

    protected function getStats(): array
    {
        // Cache the balance for 2 minutes to avoid hammering Digiflazz API
        $balanceData = Cache::remember('digiflazz:balance', 120, function () {
            $service = app(DigiflazzService::class);
            return $service->getBalance();
        });

        $balance  = $balanceData['balance'] ?? 0;
        $minAlert = (float) SystemSetting::getValue('digiflazz_min_balance_alert', '500000');
        $isCritical = $balance < $minAlert;

        return [
            Stat::make(
                'Saldo Digiflazz',
                'Rp ' . number_format($balance, 0, ',', '.')
            )
                ->description(
                    $isCritical
                        ? 'KRITIS! Saldo di bawah Rp ' . number_format($minAlert, 0, ',', '.') . ' — SEGERA TOP-UP!'
                        : 'Saldo deposit aggregator'
                )
                ->descriptionIcon($isCritical ? 'heroicon-m-exclamation-triangle' : 'heroicon-m-check-circle')
                ->color($isCritical ? 'danger' : 'success')
                ->extraAttributes($isCritical ? [
                    'class' => 'animate-pulse ring-2 ring-red-500 rounded-xl',
                ] : []),
        ];
    }
}
