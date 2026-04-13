<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained('categories')->cascadeOnDelete();
            $table->string('sku_code')->unique()->comment('Digiflazz product SKU identifier');
            $table->string('name');
            $table->decimal('base_price', 15, 2)->default(0)->comment('Cost price from Digiflazz');
            $table->decimal('admin_markup', 15, 2)->default(0)->comment('Superadmin markup per transaction');
            $table->string('type')->default('prepaid')->comment('prepaid or postpaid');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index('category_id');
            $table->index('is_active');
            $table->index(['category_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
