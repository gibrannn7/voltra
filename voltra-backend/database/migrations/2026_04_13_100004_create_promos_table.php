<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('promos', function (Blueprint $table) {
            $table->id();
            $table->string('promo_code')->unique();
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('min_transaction', 15, 2)->default(0);
            $table->unsignedInteger('max_usage')->default(0)->comment('0 = unlimited');
            $table->unsignedInteger('current_usage')->default(0);
            $table->timestamp('expired_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index('promo_code');
            $table->index('is_active');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('promos');
    }
};
