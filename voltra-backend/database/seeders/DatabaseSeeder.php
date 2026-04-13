<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\Promo;
use App\Models\SystemSetting;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // ─── 1. Users ────────────────────────────────────────
        $superadmin = User::create([
            'name'         => 'Super Admin Voltra',
            'phone_number' => '6281000000001',
            'email'        => 'admin@voltra.app',
            'password'     => Hash::make('password'),
            'pin'          => Hash::make('123456'),
            'role'         => 'superadmin',
            'kyc_status'   => 'verified',
        ]);

        $user = User::create([
            'name'         => 'Budi Santoso',
            'phone_number' => '6281000000002',
            'email'        => 'budi@example.com',
            'password'     => Hash::make('password'),
            'pin'          => Hash::make('123456'),
            'role'         => 'user',
            'voltra_points' => 500,
            'kyc_status'   => 'verified',
        ]);

        // ─── 2. Wallets ──────────────────────────────────────
        Wallet::create([
            'user_id' => $superadmin->id,
            'balance' => '1000000.00',
        ]);

        Wallet::create([
            'user_id' => $user->id,
            'balance' => '250000.00',
        ]);

        // ─── 3. Categories ──────────────────────────────────
        $plnCategory = Category::create([
            'name'       => 'PLN',
            'icon'       => 'bolt',
            'is_active'  => true,
            'sort_order' => 1,
        ]);

        $pulsaCategory = Category::create([
            'name'       => 'Pulsa',
            'icon'       => 'smartphone',
            'is_active'  => true,
            'sort_order' => 2,
        ]);

        $dataCategory = Category::create([
            'name'       => 'Paket Data',
            'icon'       => 'wifi',
            'is_active'  => true,
            'sort_order' => 3,
        ]);

        $ewalletCategory = Category::create([
            'name'       => 'E-Wallet',
            'icon'       => 'wallet',
            'is_active'  => true,
            'sort_order' => 4,
        ]);

        $gameCategory = Category::create([
            'name'       => 'Game',
            'icon'       => 'gamepad-2',
            'is_active'  => true,
            'sort_order' => 5,
        ]);

        // ─── 4. Products ─────────────────────────────────────
        // PLN Token Products
        Product::create([
            'category_id'  => $plnCategory->id,
            'sku_code'     => 'pln20',
            'name'         => 'Token Listrik 20.000',
            'base_price'   => '20000.00',
            'admin_markup' => '2500.00',
            'type'         => 'prepaid',
            'is_active'    => true,
        ]);

        Product::create([
            'category_id'  => $plnCategory->id,
            'sku_code'     => 'pln50',
            'name'         => 'Token Listrik 50.000',
            'base_price'   => '50000.00',
            'admin_markup' => '2500.00',
            'type'         => 'prepaid',
            'is_active'    => true,
        ]);

        Product::create([
            'category_id'  => $plnCategory->id,
            'sku_code'     => 'pln100',
            'name'         => 'Token Listrik 100.000',
            'base_price'   => '100000.00',
            'admin_markup' => '2500.00',
            'type'         => 'prepaid',
            'is_active'    => true,
        ]);

        Product::create([
            'category_id'  => $plnCategory->id,
            'sku_code'     => 'plnpostpaid',
            'name'         => 'Tagihan Listrik Pascabayar',
            'base_price'   => '0.00',
            'admin_markup' => '3000.00',
            'type'         => 'postpaid',
            'is_active'    => true,
        ]);

        // Pulsa Products
        Product::create([
            'category_id'  => $pulsaCategory->id,
            'sku_code'     => 'tsel10',
            'name'         => 'Pulsa Telkomsel 10.000',
            'base_price'   => '10500.00',
            'admin_markup' => '2000.00',
            'type'         => 'prepaid',
            'is_active'    => true,
        ]);

        Product::create([
            'category_id'  => $pulsaCategory->id,
            'sku_code'     => 'tsel25',
            'name'         => 'Pulsa Telkomsel 25.000',
            'base_price'   => '25200.00',
            'admin_markup' => '2000.00',
            'type'         => 'prepaid',
            'is_active'    => true,
        ]);

        Product::create([
            'category_id'  => $pulsaCategory->id,
            'sku_code'     => 'tsel50',
            'name'         => 'Pulsa Telkomsel 50.000',
            'base_price'   => '49500.00',
            'admin_markup' => '2000.00',
            'type'         => 'prepaid',
            'is_active'    => true,
        ]);

        // E-Wallet
        Product::create([
            'category_id'  => $ewalletCategory->id,
            'sku_code'     => 'gopay25',
            'name'         => 'Gopay 25.000',
            'base_price'   => '25500.00',
            'admin_markup' => '1500.00',
            'type'         => 'prepaid',
            'is_active'    => true,
        ]);

        // ─── 5. Promo ────────────────────────────────────────
        Promo::create([
            'promo_code'      => 'VOLTRA10',
            'discount_amount' => '10000.00',
            'min_transaction'  => '50000.00',
            'max_usage'       => 100,
            'current_usage'   => 0,
            'expired_at'      => now()->addMonths(3),
            'is_active'       => true,
        ]);

        Promo::create([
            'promo_code'      => 'NEWUSER',
            'discount_amount' => '5000.00',
            'min_transaction'  => '20000.00',
            'max_usage'       => 500,
            'current_usage'   => 0,
            'expired_at'      => now()->addMonths(6),
            'is_active'       => true,
        ]);

        // ─── 6. System Settings ──────────────────────────────
        SystemSetting::create([
            'key'         => 'min_app_version',
            'value'       => '1.0.0',
            'description' => 'Minimum required app version for Force Update mechanism',
        ]);

        SystemSetting::create([
            'key'         => 'is_maintenance_mode',
            'value'       => 'false',
            'description' => 'Toggle maintenance mode for mobile app',
        ]);

        SystemSetting::create([
            'key'         => 'cs_whatsapp_number',
            'value'       => '6281234567890',
            'description' => 'Customer Service WhatsApp number for help desk redirect',
        ]);

        SystemSetting::create([
            'key'         => 'max_pin_attempts',
            'value'       => '3',
            'description' => 'Maximum PIN entry attempts before account lockout',
        ]);

        SystemSetting::create([
            'key'         => 'digiflazz_min_balance_alert',
            'value'       => '500000',
            'description' => 'Digiflazz balance threshold for critical alert widget',
        ]);
    }
}
