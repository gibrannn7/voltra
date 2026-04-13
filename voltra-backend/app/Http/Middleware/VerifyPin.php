<?php

namespace App\Http\Middleware;

use App\Http\Responses\ApiResponse;
use App\Models\SystemSetting;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Symfony\Component\HttpFoundation\Response;

class VerifyPin
{
    /**
     * Validate the user's PIN from the X-Pin header.
     * Implements auto-lockout after 3 consecutive failures.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user) {
            return ApiResponse::error('Unauthorized', 401);
        }

        // Check if account is already suspended
        if ($user->is_suspended) {
            $csNumber = SystemSetting::getValue('cs_whatsapp_number', '6281234567890');
            return ApiResponse::error(
                "Akun Anda telah diblokir. Hubungi CS via WhatsApp: {$csNumber}",
                403
            );
        }

        $pin = $request->header('X-Pin');

        if (empty($pin)) {
            return ApiResponse::error('PIN is required', 422);
        }

        if (! Hash::check($pin, $user->pin)) {
            // Increment failed count
            $user->increment('failed_pin_count');

            $maxAttempts = (int) SystemSetting::getValue('max_pin_attempts', '3');

            if ($user->failed_pin_count >= $maxAttempts) {
                $user->update([
                    'is_suspended'   => true,
                    'suspend_reason' => 'Too many failed PIN attempts',
                ]);

                $csNumber = SystemSetting::getValue('cs_whatsapp_number', '6281234567890');

                return ApiResponse::error(
                    "Akun diblokir karena {$maxAttempts}x salah PIN. Hubungi CS: {$csNumber}",
                    403
                );
            }

            $remaining = $maxAttempts - $user->failed_pin_count;

            return ApiResponse::error(
                "PIN salah. {$remaining} percobaan tersisa.",
                401
            );
        }

        // PIN correct — reset failed count
        if ($user->failed_pin_count > 0) {
            $user->update(['failed_pin_count' => 0]);
        }

        return $next($request);
    }
}
