<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\ProductController;
use App\Http\Controllers\Api\V1\PromoController;
use App\Http\Controllers\Api\V1\SystemController;
use App\Http\Controllers\Api\V1\TransactionController;
use App\Http\Controllers\Api\V1\WalletController;
use App\Http\Controllers\Api\V1\WebhookController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Voltra API Routes (v1)
|--------------------------------------------------------------------------
|
| All API routes follow the /api/v1 prefix convention.
| Public routes: auth, webhooks, system checks
| Protected routes: products, transactions, wallet, notifications
|
*/

Route::prefix('v1')->group(function () {

    // ─── Public: Authentication ──────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);
    });

    // ─── Public: System ──────────────────────────────────────
    Route::prefix('system')->group(function () {
        Route::post('/check-version', [SystemController::class, 'checkVersion']);
        Route::get('/settings', [SystemController::class, 'settings']);
    });

    // ─── Public: Webhooks (no auth, signature-verified) ──────
    Route::prefix('webhooks')->group(function () {
        Route::post('/midtrans', [WebhookController::class, 'midtrans']);
        Route::post('/digiflazz', [WebhookController::class, 'digiflazz']);
    });

    // ─── Protected Routes (Sanctum + CheckSuspended + CheckMaintenance) ──
    Route::middleware(['auth:sanctum', 'check.suspended', 'check.maintenance'])->group(function () {

        // Auth (authenticated)
        Route::prefix('auth')->group(function () {
            Route::post('/verify-pin', [AuthController::class, 'verifyPin']);
            Route::put('/fcm-token', [AuthController::class, 'updateFcmToken']);
            Route::get('/profile', [AuthController::class, 'profile']);
            Route::post('/logout', [AuthController::class, 'logout']);
            Route::delete('/account', [AuthController::class, 'deleteAccount']);
        });

        // Products & Inquiry
        Route::prefix('products')->group(function () {
            Route::get('/categories', [ProductController::class, 'categories']);
            Route::get('/', [ProductController::class, 'index']);
            Route::post('/inquiry', [ProductController::class, 'inquiry'])
                ->middleware('throttle:3,1'); // 3 requests per minute
        });

        // Transactions (PIN-protected + Idempotent)
        Route::prefix('transactions')->group(function () {
            Route::get('/', [TransactionController::class, 'index']);
            Route::get('/{id}', [TransactionController::class, 'show']);
            Route::post('/', [TransactionController::class, 'store'])
                ->middleware(['verify.pin', 'idempotency', 'throttle:3,1']);
        });

        // Wallet
        Route::prefix('wallet')->group(function () {
            Route::get('/balance', [WalletController::class, 'balance']);
            Route::get('/mutations', [WalletController::class, 'mutations']);
            Route::post('/top-up', [WalletController::class, 'topUp'])
                ->middleware(['verify.pin']);
        });

        // Promos
        Route::post('/promos/validate', [PromoController::class, 'validatePromo']);

        // Notifications
        Route::prefix('notifications')->group(function () {
            Route::get('/', [NotificationController::class, 'index']);
            Route::patch('/{id}/read', [NotificationController::class, 'markRead']);
            Route::patch('/read-all', [NotificationController::class, 'markAllRead']);
        });
    });
});
