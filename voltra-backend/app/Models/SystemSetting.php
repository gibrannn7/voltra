<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class SystemSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'key',
        'value',
        'description',
    ];

    // ─── Cache TTL (seconds) ─────────────────────────────────

    const CACHE_TTL = 300; // 5 minutes

    // ─── Known Setting Keys ──────────────────────────────────

    const KEY_MIN_APP_VERSION    = 'min_app_version';
    const KEY_MAINTENANCE_MODE   = 'is_maintenance_mode';
    const KEY_CS_WHATSAPP        = 'cs_whatsapp_number';
    const KEY_MAX_PIN_ATTEMPTS   = 'max_pin_attempts';
    const KEY_DIGIFLAZZ_MIN_BAL  = 'digiflazz_min_balance_alert';

    // ─── Static Helpers ──────────────────────────────────────

    /**
     * Get a system setting value by key with caching.
     */
    public static function getValue(string $key, mixed $default = null): mixed
    {
        return Cache::remember(
            "system_setting:{$key}",
            self::CACHE_TTL,
            fn () => self::where('key', $key)->value('value') ?? $default
        );
    }

    /**
     * Set a system setting value and bust the cache.
     */
    public static function setValue(string $key, string $value): void
    {
        self::updateOrCreate(
            ['key' => $key],
            ['value' => $value]
        );

        Cache::forget("system_setting:{$key}");
    }

    /**
     * Check if maintenance mode is active.
     */
    public static function isMaintenanceMode(): bool
    {
        return self::getValue(self::KEY_MAINTENANCE_MODE, 'false') === 'true';
    }

    /**
     * Get the minimum required app version.
     */
    public static function getMinAppVersion(): string
    {
        return self::getValue(self::KEY_MIN_APP_VERSION, '1.0.0');
    }
}
