<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'balance',
        'pin_attempts',
        'is_blocked',
    ];

    protected function casts(): array
    {
        return [
            'balance'      => 'decimal:2',
            'pin_attempts' => 'integer',
            'is_blocked'   => 'boolean',
        ];
    }

    // ─── Relationships ───────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // ─── Helpers ─────────────────────────────────────────────

    /**
     * Check if wallet has sufficient balance for a given amount.
     * Uses bccomp to avoid floating-point comparison bugs.
     */
    public function hasSufficientBalance(string $amount): bool
    {
        return bccomp($this->balance, $amount, 2) >= 0;
    }
}
