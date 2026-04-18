<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DummyTransactionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     * Menginjeksi data transaksi simulasi ke hari ini untuk menghidupkan Dasbor.
     */
    public function run(): void
    {
        $user = User::where('role', 'user')->first();

        if (!$user) {
            return;
        }

        $products = Product::where('is_active', true)->get();

        if ($products->isEmpty()) {
            return;
        }

        $today = now();


        $scenarios = [
            ['sku' => 'pln100',  'status' => Transaction::STATUS_SUCCESS,    'time' => $today->copy()->subHours(2)],
            ['sku' => 'pln50',   'status' => Transaction::STATUS_SUCCESS,    'time' => $today->copy()->subHours(3)],
            ['sku' => 'gopay25', 'status' => Transaction::STATUS_SUCCESS,    'time' => $today->copy()->subHours(4)],
            ['sku' => 'tsel50',  'status' => Transaction::STATUS_SUCCESS,    'time' => $today->copy()->subHours(1)],
            ['sku' => 'tsel25',  'status' => Transaction::STATUS_PROCESSING, 'time' => $today->copy()->subMinutes(15)],
            ['sku' => 'tsel10',  'status' => Transaction::STATUS_FAILED,     'time' => $today->copy()->subHours(5)],
        ];

        foreach ($scenarios as $scenario) {
            $product = $products->where('sku_code', $scenario['sku'])->first();

            if ($product) {
                $this->createTransaction($user, $product, $scenario['status'], $scenario['time']);
            }
        }
    }

    /**
     * Engine pembuatan transaksi dengan presisi BCMath.
     */
    private function createTransaction(User $user, Product $product, string $status, \Carbon\Carbon $createdAt): void
    {
        $basePrice = $product->base_price;
        $adminFee = $product->admin_markup;
        $totalAmount = bcadd($basePrice, $adminFee, 2);

        Transaction::create([
            'user_id' => $user->id,
            'product_id' => $product->id,
            'customer_number' => '0812'.mt_rand(10000000, 99999999),
            'customer_name' => 'Voltra Client',
            'base_price' => $basePrice,
            'admin_fee' => $adminFee,
            'discount' => '0.00',
            'pg_fee' => '0.00',
            'total_amount' => $totalAmount,
            'profit_margin' => $adminFee,
            'status' => $status,
            'payment_method' => 'wallet',
            'midtrans_order_id' => 'VLT-'.$createdAt->format('YmdHis').'-'.Str::upper(Str::random(4)),
            'digiflazz_ref_id' => 'DGF-'.$createdAt->format('YmdHis').'-'.Str::upper(Str::random(4)),
            'created_at' => $createdAt,
            'updated_at' => $createdAt,
        ]);
    }
}
