<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('api_logs', function (Blueprint $table) {
            $table->id();
            $table->enum('provider', ['midtrans', 'digiflazz']);
            $table->enum('type', ['request', 'webhook']);
            $table->string('endpoint');
            $table->json('payload')->nullable();
            $table->json('response')->nullable();
            $table->unsignedSmallInteger('http_status')->nullable();
            $table->timestamps();

            $table->index(['provider', 'type']);
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('api_logs');
    }
};
