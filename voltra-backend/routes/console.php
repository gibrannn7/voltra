<?php

use App\Jobs\CheckUnpaidBills;
use App\Jobs\SyncDigiflazzProducts;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

/*
|--------------------------------------------------------------------------
| Voltra Scheduled Commands
|--------------------------------------------------------------------------
|
| Cron Jobs (from Blueprint):
| - Daily @ 09:00 WIB: Check unpaid postpaid bills, send FCM reminders
| - Hourly: Sync product catalog & prices from Digiflazz (cache refresh)
|
*/

// Daily bill reminder at 09:00 WIB (Asia/Jakarta)
Schedule::job(new CheckUnpaidBills)
    ->dailyAt('09:00')
    ->timezone('Asia/Jakarta')
    ->withoutOverlapping()
    ->onOneServer();

// Hourly product/price sync from Digiflazz
Schedule::job(new SyncDigiflazzProducts)
    ->hourly()
    ->withoutOverlapping()
    ->onOneServer();

// Keep the default inspire command
Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();
