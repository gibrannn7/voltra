<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ApiLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'provider',
        'type',
        'endpoint',
        'payload',
        'response',
        'http_status',
    ];

    protected function casts(): array
    {
        return [
            'payload'     => 'array',
            'response'    => 'array',
            'http_status' => 'integer',
        ];
    }

    // ─── Provider Constants ──────────────────────────────────

    const PROVIDER_MIDTRANS  = 'midtrans';
    const PROVIDER_DIGIFLAZZ = 'digiflazz';

    const TYPE_REQUEST = 'request';
    const TYPE_WEBHOOK = 'webhook';

    // ─── Scopes ──────────────────────────────────────────────

    public function scopeForProvider($query, string $provider)
    {
        return $query->where('provider', $provider);
    }

    public function scopeWebhooks($query)
    {
        return $query->where('type', self::TYPE_WEBHOOK);
    }

    public function scopeRequests($query)
    {
        return $query->where('type', self::TYPE_REQUEST);
    }
}
