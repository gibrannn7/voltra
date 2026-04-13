<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Services\MidtransService;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class WalletController extends Controller
{
    public function __construct(
        private WalletService $walletService,
        private MidtransService $midtransService,
    ) {}

    /**
     * Get the current wallet balance.
     *
     * GET /api/v1/wallet/balance
     */
    public function balance(Request $request): JsonResponse
    {
        $user    = $request->user();
        $balance = $this->walletService->getBalance($user);

        return ApiResponse::success([
            'balance' => $balance,
        ], 'Wallet balance');
    }

    /**
     * Initiate a wallet top-up via Midtrans.
     * PIN-protected.
     *
     * POST /api/v1/wallet/top-up
     */
    public function topUp(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:10000|max:10000000',
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator->errors());
        }

        $user    = $request->user();
        $amount  = (string) $request->amount;
        $orderId = 'TOPUP-' . now()->format('YmdHis') . '-' . Str::upper(Str::random(4));

        $snapResult = $this->midtransService->createSnapTransaction(
            $orderId,
            $amount,
            [
                'name'  => $user->name,
                'email' => $user->email ?? 'user@voltra.app',
                'phone' => $user->phone_number,
            ]
        );

        if (! $snapResult['success']) {
            return ApiResponse::error($snapResult['message'], 422);
        }

        return ApiResponse::success([
            'order_id'     => $orderId,
            'amount'       => $amount,
            'snap_token'   => $snapResult['snap_token'],
            'redirect_url' => $snapResult['redirect_url'],
        ], 'Top-up payment created');
    }

    /**
     * Get paginated wallet balance mutations.
     *
     * GET /api/v1/wallet/mutations
     */
    public function mutations(Request $request): JsonResponse
    {
        $mutations = $request->user()
            ->balanceMutations()
            ->with('transaction:id,product_id,status')
            ->orderByDesc('created_at')
            ->paginate($request->query('per_page', 20));

        $formatted = $mutations->through(fn ($m) => [
            'id'             => $m->id,
            'type'           => $m->type,
            'amount'         => $m->amount,
            'description'    => $m->description,
            'transaction_id' => $m->reference_id,
            'created_at'     => $m->created_at?->toIso8601String(),
        ]);

        return ApiResponse::paginated($formatted, 'Wallet mutations');
    }
}
