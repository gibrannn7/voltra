<?php

namespace App\Http\Middleware;

use App\Http\Responses\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

class IdempotencyCheck
{
    /**
     * Prevent duplicate transaction submissions using the X-Idempotency-Key header.
     *
     * Uses a cache lock to prevent race conditions when the same key
     * is submitted simultaneously from multiple requests.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $idempotencyKey = $request->header('X-Idempotency-Key');

        if (empty($idempotencyKey)) {
            return ApiResponse::error(
                'X-Idempotency-Key header is required for transaction endpoints',
                422
            );
        }

        $cacheKey = 'idempotency:' . $idempotencyKey;

        // Check if this key was already processed (within the last 24 hours)
        if (Cache::has($cacheKey)) {
            return ApiResponse::error(
                'This request has already been processed. Please use a new idempotency key.',
                409
            );
        }

        // Attempt to acquire a lock for this key (10 second window)
        $lock = Cache::lock('lock:' . $cacheKey, 10);

        if (! $lock->get()) {
            return ApiResponse::error(
                'Request is already being processed. Please wait.',
                429
            );
        }

        try {
            // Mark this key as "in progress" — TTL 24 hours
            Cache::put($cacheKey, true, now()->addHours(24));

            $response = $next($request);

            return $response;
        } finally {
            $lock->release();
        }
    }
}
