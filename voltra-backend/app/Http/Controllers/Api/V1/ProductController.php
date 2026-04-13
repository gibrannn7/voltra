<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Category;
use App\Models\Product;
use App\Services\DigiflazzService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Validator;

class ProductController extends Controller
{
    public function __construct(
        private DigiflazzService $digiflazzService,
    ) {}

    /**
     * Get all active categories.
     *
     * GET /api/v1/products/categories
     */
    public function categories(): JsonResponse
    {
        $categories = Cache::remember('categories:active', 3600, function () {
            return Category::active()
                ->orderBy('sort_order')
                ->get(['id', 'name', 'icon', 'sort_order']);
        });

        return ApiResponse::success($categories, 'Categories retrieved');
    }

    /**
     * Get products by category (cached for 1 hour).
     *
     * GET /api/v1/products?category_id=1
     */
    public function index(Request $request): JsonResponse
    {
        $categoryId = $request->query('category_id');

        $cacheKey = "products:category:{$categoryId}";

        $products = Cache::remember($cacheKey, 3600, function () use ($categoryId) {
            $query = Product::active()->with('category:id,name,icon');

            if ($categoryId) {
                $query->where('category_id', $categoryId);
            }

            return $query->orderBy('base_price')
                ->get()
                ->map(fn (Product $product) => [
                    'id'            => $product->id,
                    'sku_code'      => $product->sku_code,
                    'name'          => $product->name,
                    'category'      => $product->category?->name,
                    'category_icon' => $product->category?->icon,
                    'base_price'    => $product->base_price,
                    'admin_fee'     => $product->admin_markup,
                    'selling_price' => $product->selling_price,
                    'type'          => $product->type,
                ]);
        });

        return ApiResponse::success($products, 'Products retrieved');
    }

    /**
     * Perform a PLN / product inquiry via Digiflazz.
     * Rate-limited: 3 requests per minute per user.
     *
     * POST /api/v1/products/inquiry
     */
    public function inquiry(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'sku_code'        => 'required|string|exists:products,sku_code',
            'customer_number' => 'required|string|min:6|max:20',
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator->errors());
        }

        $product = Product::where('sku_code', $request->sku_code)->active()->first();

        if (! $product) {
            return ApiResponse::error('Produk tidak ditemukan atau sedang tidak aktif', 404);
        }

        $result = $this->digiflazzService->inquiry(
            $request->sku_code,
            $request->customer_number
        );

        if (! $result['success']) {
            return ApiResponse::error($result['message'], 422);
        }

        $inquiryData = $result['data'];

        return ApiResponse::success([
            'product'         => [
                'id'            => $product->id,
                'sku_code'      => $product->sku_code,
                'name'          => $product->name,
                'base_price'    => $product->base_price,
                'admin_fee'     => $product->admin_markup,
                'selling_price' => $product->selling_price,
            ],
            'customer_number' => $request->customer_number,
            'customer_name'   => $inquiryData['customer_name'] ?? $inquiryData['customer_no'] ?? null,
            'ref_id'          => $result['ref_id'],
            'inquiry_data'    => $inquiryData,
        ], 'Inquiry berhasil');
    }
}
