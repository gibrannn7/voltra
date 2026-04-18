<?php

namespace App\Providers;

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Memastikan kompatibilitas migrasi index string untuk MySQL 5.x
        Schema::defaultStringLength(191);

        // Memaksa penggunaan HTTPS jika aplikasi diakses melalui Ngrok atau berada di environment production
        // Ini akan memperbaiki masalah mixed content yang menyebabkan aset CSS/JS Filament gagal dimuat
        if ($this->app->environment('production') || str_contains(request()->getHost(), 'ngrok-free.app')) {
            URL::forceScheme('https');
        }
    }
}
