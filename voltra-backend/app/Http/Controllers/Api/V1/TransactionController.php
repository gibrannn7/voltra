<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Product;
use App\Services\TransactionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class TransactionController extends Controller
{
    public function __construct(
        private TransactionService $transactionService,
    ) {}

    /**
     * Create a new transaction.
     * Protected by: auth:sanctum + verify.pin + idempotency middleware.
     *
     * POST /api/v1/transactions
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'product_id'      => 'required|integer|exists:products,id',
            'customer_number' => 'required|string|min:6|max:20',
            'customer_name'   => 'nullable|string|max:100',
            'payment_method'  => 'required|string|in:wallet,bank_transfer,gopay,shopeepay,qris',
            'promo_code'      => 'nullable|string|max:50',
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator->errors());
        }

        $product = Product::findOrFail($request->product_id);
        $user    = $request->user();

        $idempotencyKey = $request->header('X-Idempotency-Key');

        $result = $this->transactionService->createTransaction(
            user: $user,
            product: $product,
            customerNumber: $request->customer_number,
            paymentMethod: $request->payment_method,
            promoCode: $request->promo_code,
            idempotencyKey: $idempotencyKey,
            customerName: $request->customer_name,
        );

        if (! $result['success']) {
            return ApiResponse::error($result['message'], 422);
        }

        $responseData = [
            'transaction' => $this->formatTransaction($result['transaction']),
        ];

        // Include Midtrans Snap token if applicable
        if (isset($result['snap_token'])) {
            $responseData['snap_token']   = $result['snap_token'];
            $responseData['redirect_url'] = $result['redirect_url'];
        }

        // Include SN/token if immediately available (wallet payment)
        if (isset($result['sn_token'])) {
            $responseData['sn_token'] = $result['sn_token'];
        }

        $statusCode = isset($result['duplicate']) ? 200 : 201;

        return ApiResponse::success(
            $responseData,
            $result['message'],
            $statusCode
        );
    }

    /**
     * Get the authenticated user's transaction history (paginated).
     *
     * GET /api/v1/transactions
     */
    public function index(Request $request): JsonResponse
    {
        $transactions = $request->user()
            ->transactions()
            ->with('product:id,name,sku_code')
            ->orderByDesc('created_at')
            ->paginate($request->query('per_page', 15));

        $formatted = $transactions->through(fn ($tx) => $this->formatTransaction($tx));

        return ApiResponse::paginated($formatted, 'Transaction history');
    }

    /**
     * Get a single transaction detail.
     *
     * GET /api/v1/transactions/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $transaction = $request->user()
            ->transactions()
            ->with(['product:id,name,sku_code,category_id', 'product.category:id,name', 'promo:id,promo_code,discount_amount'])
            ->findOrFail($id);

        return ApiResponse::success(
            $this->formatTransaction($transaction, detailed: true),
            'Transaction detail'
        );
    }

    /**
     * Format a transaction for API response.
     */
    private function formatTransaction($transaction, bool $detailed = false): array
    {
        $data = [
            'id'              => $transaction->id,
            'product_name'    => $transaction->product?->name,
            'product_sku'     => $transaction->product?->sku_code,
            'customer_number' => $transaction->customer_number,
            'customer_name'   => $transaction->customer_name,
            'total_amount'    => $transaction->total_amount,
            'status'          => $transaction->status,
            'payment_method'  => $transaction->payment_method,
            'sn_token'        => $transaction->sn_token,
            'created_at'      => $transaction->created_at?->toIso8601String(),
        ];

        if ($detailed) {
            $data = array_merge($data, [
                'base_price'        => $transaction->base_price,
                'admin_fee'         => $transaction->admin_fee,
                'discount'          => $transaction->discount,
                'pg_fee'            => $transaction->pg_fee,
                'profit_margin'     => $transaction->profit_margin,
                'midtrans_order_id' => $transaction->midtrans_order_id,
                'digiflazz_ref_id'  => $transaction->digiflazz_ref_id,
                'category'          => $transaction->product?->category?->name,
                'promo_code'        => $transaction->promo?->promo_code,
                'promo_discount'    => $transaction->promo?->discount_amount,
                'updated_at'        => $transaction->updated_at?->toIso8601String(),
            ]);
        }

        return $data;
    }
}
