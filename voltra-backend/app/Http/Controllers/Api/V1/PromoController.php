<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Promo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PromoController extends Controller
{
    /**
     * Validate a promo code for a given transaction amount.
     *
     * POST /api/v1/promos/validate
     */
    public function validatePromo(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'promo_code' => 'required|string|max:50',
            'amount'     => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator->errors());
        }

        $promo = Promo::where('promo_code', $request->promo_code)->first();

        if (! $promo) {
            return ApiResponse::error('Kode promo tidak ditemukan', 404);
        }

        $amount = (string) $request->amount;

        if (! $promo->isValidForAmount($amount)) {
            $reasons = [];

            if (! $promo->is_active) {
                $reasons[] = 'Promo sudah tidak aktif';
            }
            if ($promo->expired_at && $promo->expired_at->isPast()) {
                $reasons[] = 'Promo sudah kedaluwarsa';
            }
            if ($promo->max_usage > 0 && $promo->current_usage >= $promo->max_usage) {
                $reasons[] = 'Kuota promo sudah habis';
            }
            if (bccomp($amount, $promo->min_transaction, 2) < 0) {
                $reasons[] = "Minimum transaksi Rp " . number_format((float) $promo->min_transaction, 0, ',', '.');
            }

            return ApiResponse::error(
                implode('. ', $reasons) ?: 'Promo tidak dapat digunakan',
                422
            );
        }

        return ApiResponse::success([
            'promo_code'      => $promo->promo_code,
            'discount_amount' => $promo->discount_amount,
            'min_transaction' => $promo->min_transaction,
            'expired_at'      => $promo->expired_at?->toIso8601String(),
        ], 'Promo valid');
    }
}
