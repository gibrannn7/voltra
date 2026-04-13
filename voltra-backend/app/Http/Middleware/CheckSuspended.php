<?php

namespace App\Http\Middleware;

use App\Http\Responses\ApiResponse;
use App\Models\SystemSetting;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckSuspended
{
    /**
     * Block suspended/locked users from accessing protected endpoints.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->is_suspended) {
            $csNumber = SystemSetting::getValue('cs_whatsapp_number', '6281234567890');
            $reason   = $user->suspend_reason ?? 'Account suspended';

            return ApiResponse::error(
                "Akun Anda diblokir: {$reason}. Hubungi CS via WhatsApp: {$csNumber}",
                403
            );
        }

        return $next($request);
    }
}
