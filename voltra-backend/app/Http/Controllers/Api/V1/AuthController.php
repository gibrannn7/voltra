<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    /**
     * Register a new user account.
     *
     * POST /api/v1/auth/register
     */
    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name'         => 'required|string|max:255',
            'phone_number' => 'required|string|unique:users,phone_number|regex:/^62[0-9]{9,13}$/',
            'email'        => 'nullable|email|unique:users,email',
            'password'     => 'required|string|min:8|confirmed',
            'pin'          => 'required|digits:6',
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator->errors());
        }

        $user = User::create([
            'name'         => $request->name,
            'phone_number' => $request->phone_number,
            'email'        => $request->email,
            'password'     => Hash::make($request->password),
            'pin'          => Hash::make($request->pin),
            'role'         => 'user',
        ]);

        // Create wallet for the new user
        Wallet::create([
            'user_id' => $user->id,
            'balance' => '0.00',
        ]);

        $token = $user->createToken('voltra-mobile')->plainTextToken;

        return ApiResponse::success([
            'user'  => $this->formatUser($user),
            'token' => $token,
        ], 'Registrasi berhasil', 201);
    }

    /**
     * Login with phone number and password.
     *
     * POST /api/v1/auth/login
     */
    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => 'required|string',
            'password'     => 'required|string',
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator->errors());
        }

        $user = User::where('phone_number', $request->phone_number)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return ApiResponse::error('Nomor HP atau password salah', 401);
        }

        if ($user->is_suspended) {
            return ApiResponse::error(
                'Akun Anda telah diblokir. Hubungi Customer Service.',
                403
            );
        }

        // Revoke previous tokens (single-device session)
        $user->tokens()->delete();

        $token = $user->createToken('voltra-mobile')->plainTextToken;

        return ApiResponse::success([
            'user'  => $this->formatUser($user->load('wallet')),
            'token' => $token,
        ], 'Login berhasil');
    }

    /**
     * Verify PIN (for transaction confirmation).
     *
     * POST /api/v1/auth/verify-pin
     */
    public function verifyPin(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'pin' => 'required|digits:6',
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator->errors());
        }

        $user = $request->user();

        if (! Hash::check($request->pin, $user->pin)) {
            $user->increment('failed_pin_count');

            if ($user->failed_pin_count >= 3) {
                $user->update([
                    'is_suspended'   => true,
                    'suspend_reason' => 'Too many failed PIN attempts',
                ]);

                return ApiResponse::error('Akun diblokir karena 3x salah PIN', 403);
            }

            $remaining = 3 - $user->failed_pin_count;

            return ApiResponse::error("PIN salah. {$remaining} percobaan tersisa.", 401);
        }

        // Reset on success
        if ($user->failed_pin_count > 0) {
            $user->update(['failed_pin_count' => 0]);
        }

        return ApiResponse::success(null, 'PIN verified');
    }

    /**
     * Update the user's FCM token for push notifications.
     *
     * PUT /api/v1/auth/fcm-token
     */
    public function updateFcmToken(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'fcm_token' => 'required|string',
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator->errors());
        }

        $request->user()->update(['fcm_token' => $request->fcm_token]);

        return ApiResponse::success(null, 'FCM token updated');
    }

    /**
     * Get the authenticated user's profile.
     *
     * GET /api/v1/auth/profile
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user()->load('wallet');

        return ApiResponse::success($this->formatUser($user));
    }

    /**
     * Soft delete the user's account (App Store / Play Store requirement).
     *
     * DELETE /api/v1/auth/account
     */
    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();

        // Revoke all tokens
        $user->tokens()->delete();

        // Soft delete the user
        $user->delete();

        return ApiResponse::success(null, 'Akun berhasil dihapus');
    }

    /**
     * Logout and revoke the current token.
     *
     * POST /api/v1/auth/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return ApiResponse::success(null, 'Logout berhasil');
    }

    /**
     * Format user data for API response.
     */
    private function formatUser(User $user): array
    {
        return [
            'id'            => $user->id,
            'name'          => $user->name,
            'phone_number'  => $user->phone_number,
            'email'         => $user->email,
            'voltra_points' => $user->voltra_points,
            'role'          => $user->role,
            'kyc_status'    => $user->kyc_status,
            'wallet_balance' => $user->wallet?->balance ?? '0.00',
            'created_at'    => $user->created_at?->toIso8601String(),
        ];
    }
}
