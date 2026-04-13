<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'product_id',
        'promo_id',
        'customer_number',
        'customer_name',
        'base_price',
        'admin_fee',
        'discount',
        'pg_fee',
        'total_amount',
        'profit_margin',
        'status',
        'payment_method',
        'midtrans_order_id',
        'digiflazz_ref_id',
        'sn_token',
        'idempotency_key',
    ];

    protected function casts(): array
    {
        return [
            'base_price'    => 'decimal:2',
            'admin_fee'     => 'decimal:2',
            'discount'      => 'decimal:2',
            'pg_fee'        => 'decimal:2',
            'total_amount'  => 'decimal:2',
            'profit_margin' => 'decimal:2',
        ];
    }

    // ─── Status Constants ────────────────────────────────────

    const STATUS_PENDING    = 'pending';
    const STATUS_PROCESSING = 'processing';
    const STATUS_SUCCESS    = 'success';
    const STATUS_FAILED     = 'failed';

    // ─── Relationships ───────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function promo(): BelongsTo
    {
        return $this->belongsTo(Promo::class);
    }

    public function balanceMutations(): HasMany
    {
        return $this->hasMany(BalanceMutation::class, 'reference_id');
    }

    public function apiLogs(): HasMany
    {
        return $this->hasMany(ApiLog::class, 'endpoint', 'midtrans_order_id');
    }

    // ─── Scopes ──────────────────────────────────────────────

    public function scopeSuccessful($query)
    {
        return $query->where('status', self::STATUS_SUCCESS);
    }

    public function scopeFailed($query)
    {
        return $query->where('status', self::STATUS_FAILED);
    }

    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    // ─── Helpers ─────────────────────────────────────────────

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function isProcessing(): bool
    {
        return $this->status === self::STATUS_PROCESSING;
    }

    public function isSuccessful(): bool
    {
        return $this->status === self::STATUS_SUCCESS;
    }

    public function isFailed(): bool
    {
        return $this->status === self::STATUS_FAILED;
    }

    /**
     * Check if the transaction was paid via wallet.
     */
    public function isPaidViaWallet(): bool
    {
        return $this->payment_method === 'wallet';
    }
}
