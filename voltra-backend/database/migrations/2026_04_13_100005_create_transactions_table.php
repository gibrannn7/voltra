<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users');
            $table->foreignId('product_id')->constrained('products');
            $table->foreignId('promo_id')->nullable()->constrained('promos');
            $table->string('customer_number')->comment('PLN meter number or phone number');
            $table->string('customer_name')->nullable()->comment('From inquiry response');
            $table->decimal('base_price', 15, 2)->default(0)->comment('Snapshot of product cost at transaction time');
            $table->decimal('admin_fee', 15, 2)->default(0)->comment('Snapshot of admin markup');
            $table->decimal('discount', 15, 2)->default(0);
            $table->decimal('pg_fee', 15, 2)->default(0)->comment('Payment gateway fee');
            $table->decimal('total_amount', 15, 2)->default(0)->comment('Final amount charged');
            $table->decimal('profit_margin', 15, 2)->default(0)->comment('Frozen profit snapshot per transaction');
            $table->enum('status', ['pending', 'processing', 'success', 'failed'])->default('pending');
            $table->string('payment_method')->nullable()->comment('e.g., QRIS, ShopeePay, wallet');
            $table->string('midtrans_order_id')->nullable()->unique();
            $table->string('digiflazz_ref_id')->nullable();
            $table->string('sn_token')->nullable()->comment('Serial Number / Token Listrik from Digiflazz');
            $table->string('idempotency_key')->nullable()->unique()->comment('Prevent duplicate submissions');
            $table->timestamps();

            // Composite indexes for high-performance queries
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'created_at']);
            $table->index('midtrans_order_id');
            $table->index('digiflazz_ref_id');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
