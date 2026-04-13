<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\SystemSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SystemController extends Controller
{
    /**
     * Check if the app version is supported.
     * Returns force_update flag if the app is outdated.
     *
     * POST /api/v1/system/check-version
     */
    public function checkVersion(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'current_version' => 'required|string',
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator->errors());
        }

        $minVersion    = SystemSetting::getMinAppVersion();
        $currentVersion = $request->current_version;

        $needsUpdate = version_compare($currentVersion, $minVersion, '<');

        return ApiResponse::success([
            'force_update'    => $needsUpdate,
            'min_version'     => $minVersion,
            'current_version' => $currentVersion,
            'store_url'       => [
                'android' => 'https://play.google.com/store/apps/details?id=app.voltra.mobile',
                'ios'     => 'https://apps.apple.com/app/voltra/id000000000',
            ],
        ], $needsUpdate ? 'Silakan update aplikasi ke versi terbaru' : 'App is up to date');
    }

    /**
     * Get public system settings (maintenance mode, CS number).
     *
     * GET /api/v1/system/settings
     */
    public function settings(): JsonResponse
    {
        return ApiResponse::success([
            'is_maintenance_mode' => SystemSetting::isMaintenanceMode(),
            'min_app_version'     => SystemSetting::getMinAppVersion(),
            'cs_whatsapp_number'  => SystemSetting::getValue('cs_whatsapp_number', '6281234567890'),
        ], 'System settings');
    }
}
