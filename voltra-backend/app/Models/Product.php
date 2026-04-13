<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'category_id',
        'sku_code',
        'name',
        'base_price',
        'admin_markup',
        'type',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'base_price'   => 'decimal:2',
            'admin_markup' => 'decimal:2',
            'is_active'    => 'boolean',
        ];
    }

    // ─── Accessors ───────────────────────────────────────────

    /**
     * Get the selling price (base_price + admin_markup).
     */
    public function getSellingPriceAttribute(): string
    {
        return bcadd($this->base_price, $this->admin_markup, 2);
    }

    // ─── Relationships ───────────────────────────────────────

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    // ─── Scopes ──────────────────────────────────────────────

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
