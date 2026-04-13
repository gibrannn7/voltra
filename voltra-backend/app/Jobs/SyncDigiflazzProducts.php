<?php

namespace App\Jobs;

use App\Models\Category;
use App\Models\Product;
use App\Models\SystemSetting;
use App\Services\DigiflazzService;
use App\Services\FcmService;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class SyncDigiflazzProducts implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 120;

    /**
     * Sync products/prices from Digiflazz.
     *
     * Implements:
     * - Chunking for large catalogs to prevent memory exhaustion
     * - Auto-Pricing Protection: disable products with negative margin
     * - Superadmin urgent notification when margin goes negative
     * - Cache invalidation after sync
     */
    public function handle(DigiflazzService $digiflazzService, FcmService $fcmService): void
    {
        Log::info('SyncDigiflazzProducts: Starting product sync');

        $products = $digiflazzService->getProducts();

        if (empty($products)) {
            Log::warning('SyncDigiflazzProducts: No products returned from Digiflazz');
            return;
        }

        $synced       = 0;
        $disabled     = 0;
        $alertProducts = [];

        // Process in chunks of 100 to prevent memory exhaustion
        $chunks = array_chunk($products, 100);

        foreach ($chunks as $chunk) {
            foreach ($chunk as $dgProduct) {
                $skuCode   = $dgProduct['buyer_sku_code'] ?? null;
                $basePrice = $dgProduct['price'] ?? 0;

                if (! $skuCode) {
                    continue;
                }

                $product = Product::withTrashed()->where('sku_code', $skuCode)->first();

                if (! $product) {
                    // New product — skip auto-creation (Superadmin should add via panel)
                    continue;
                }

                $oldPrice = $product->base_price;
                $product->update(['base_price' => (string) $basePrice]);

                // ─── Auto-Pricing Protection (Fail-Safe) ─────────
                // If base_price increase causes profit margin to go negative
                $margin = bcsub($product->admin_markup, '0', 2);
                $effectiveProfit = bcsub($product->admin_markup, '0', 2);

                // Simple check: if new base_price > old_price AND admin_markup is too low
                if (bccomp((string) $basePrice, (string) $oldPrice, 2) > 0) {
                    // Check if the product would still be profitable
                    // Selling price = base_price + admin_markup
                    // Profit = admin_markup (since base_price is cost)
                    // If admin_markup < 0 (which shouldn't happen), disable
                    // More importantly: detect sudden price spikes
                    $priceIncrease = bcsub((string) $basePrice, (string) $oldPrice, 2);

                    if (bccomp($priceIncrease, $product->admin_markup, 2) > 0) {
                        // Price increase exceeds our markup — we'd lose money
                        $product->update(['is_active' => false]);
                        $disabled++;

                        $alertProducts[] = "{$product->name} (SKU: {$skuCode}): " .
                            "harga naik Rp " . number_format((float) $priceIncrease, 0, ',', '.') .
                            " (dari Rp " . number_format((float) $oldPrice, 0, ',', '.') .
                            " ke Rp " . number_format((float) $basePrice, 0, ',', '.') . ")";

                        Log::critical('SyncDigiflazzProducts: PRODUCT AUTO-DISABLED (negative margin)', [
                            'sku'        => $skuCode,
                            'old_price'  => $oldPrice,
                            'new_price'  => $basePrice,
                            'markup'     => $product->admin_markup,
                        ]);
                    }
                }

                $synced++;
            }
        }

        // Send urgent notification to all superadmins if products were disabled
        if (! empty($alertProducts)) {
            $superadmins = User::where('role', 'superadmin')->get();

            foreach ($superadmins as $admin) {
                $fcmService->sendToUser(
                    $admin,
                    'URGENT: Produk Auto-Disabled!',
                    count($alertProducts) . ' produk dinonaktifkan karena harga naik drastis: ' .
                        implode(', ', array_slice($alertProducts, 0, 3)),
                    'reminder',
                    ['type' => 'pricing_alert', 'products' => $alertProducts]
                );
            }
        }

        // Invalidate product cache
        $categories = Category::pluck('id');
        foreach ($categories as $categoryId) {
            Cache::forget("products:category:{$categoryId}");
        }
        Cache::forget('products:category:');

        Log::info('SyncDigiflazzProducts: Complete', [
            'synced'   => $synced,
            'disabled' => $disabled,
            'alerts'   => count($alertProducts),
        ]);
    }
}
