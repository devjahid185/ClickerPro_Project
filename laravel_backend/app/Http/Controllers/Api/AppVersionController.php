<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\Request;

/**
 * Over-the-air update channel for the Android app (no Play Store needed).
 *
 * The mobile app calls GET /api/app/version on launch and compares the
 * returned versionCode with its own. If the server's is higher it shows an
 * "Update available" dialog that opens the apkUrl (the APK hosted on the
 * landing site).
 *
 * Values are stored as AppSetting rows so an admin can bump them from the
 * admin panel without a redeploy. Sensible defaults are returned when no
 * row exists yet.
 */
class AppVersionController extends Controller
{
    public function show()
    {
        return response()->json([
            'data' => [
                // Integer build number — the app compares this against its own.
                'versionCode' => (int) AppSetting::getValue('app_version_code', 1),
                // Human label shown in the dialog.
                'versionName' => AppSetting::getValue('app_version_name', '1.0.0'),
                // Where to download the latest APK.
                'apkUrl' => AppSetting::getValue(
                    'app_apk_url',
                    'https://graphy7.tech/Graphy7.apk'
                ),
                // When true, the user cannot dismiss the update (forced).
                'forceUpdate' => (bool) AppSetting::getValue('app_force_update', false),
                // Optional "what's new" note.
                'releaseNotes' => AppSetting::getValue('app_release_notes', ''),
            ],
        ]);
    }

    /** Admin-only: update the version metadata from the admin panel. */
    public function update(Request $request)
    {
        $data = $request->validate([
            'versionCode' => 'nullable|integer|min:1',
            'versionName' => 'nullable|string|max:20',
            'apkUrl' => 'nullable|url',
            'forceUpdate' => 'nullable|boolean',
            'releaseNotes' => 'nullable|string|max:1000',
        ]);

        $map = [
            'versionCode' => 'app_version_code',
            'versionName' => 'app_version_name',
            'apkUrl' => 'app_apk_url',
            'forceUpdate' => 'app_force_update',
            'releaseNotes' => 'app_release_notes',
        ];
        foreach ($map as $field => $key) {
            if (array_key_exists($field, $data) && $data[$field] !== null) {
                AppSetting::setValue($key, $data[$field]);
            }
        }

        return $this->show();
    }
}
