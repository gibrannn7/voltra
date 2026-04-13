<?php

namespace App\Http\Middleware;

use App\Http\Responses\ApiResponse;
use App\Models\SystemSetting;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckMaintenance
{
    /**
     * Return a 503 maintenance response if maintenance mode is active
     * in system_settings.
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (SystemSetting::isMaintenanceMode()) {
            return ApiResponse::error(
                'Server sedang dalam perbaikan. Silakan coba beberapa saat lagi.',
                503
            );
        }

        return $next($request);
    }
}
