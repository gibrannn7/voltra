<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Promo extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'promo_code',
        'discount_amount',
        'min_transaction',
        'max_usage',
        'current_usage',
        'expired_at',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'discount_amount' => 'decimal:2',
            'min_transaction' => 'decimal:2',
            'max_usage'       => 'integer',
            'current_usage'   => 'integer',
            'expired_at'      => 'datetime',
            'is_active'       => 'boolean',
        ];
    }

    // ─── Scopes ──────────────────────────────────────────────

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeValid($query)
    {
        return $query->active()
            ->where(function ($q) {
                $q->whereNull('expired_at')
                  ->orWhere('expired_at', '>', now());
            })
            ->where(function ($q) {
                $q->where('max_usage', 0)
                  ->orWhereColumn('current_usage', '<', 'max_usage');
            });
    }

    // ─── Helpers ─────────────────────────────────────────────

    /**
     * Check if the promo is still valid for a given transaction amount.
     */
    public function isValidForAmount(string $amount): bool
    {
        if (! $this->is_active) {
            return false;
        }

        if ($this->expired_at && $this->expired_at->isPast()) {
            return false;
        }

        if ($this->max_usage > 0 && $this->current_usage >= $this->max_usage) {
            return false;
        }

        if (bccomp($amount, $this->min_transaction, 2) < 0) {
            return false;
        }

        return true;
    }
}
