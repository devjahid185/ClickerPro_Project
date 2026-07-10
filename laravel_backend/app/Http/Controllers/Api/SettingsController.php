<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    // Keys containing any of these are treated as secret — their value is
    // masked on read and only overwritten on save when a new value is sent.
    private const SECRET_HINTS = ['password', 'secret', 'key', 'token', 'apikey', 'api_key'];

    private static function getDefaultSettings(): array
    {
        return [
            'landing.hero_title' => 'Run Your Photography Business With Confidence.',
            'landing.hero_subtitle' => 'Built for Bangladesh studios that want bookings, teams and money managed in a single, modern platform.',
            'landing.hero_description' => 'Clicker Pro gives you the mobile app and web dashboard to run your photography company like a pro.',
            'landing.feature_headline' => 'Smart tools for booking, team, finance and delivery.',
            'landing.feature_subheadline' => 'Everything your photography company needs with a premium, professional user experience.',
            'landing.detail_mobile_title' => 'Mobile App',
            'landing.detail_mobile_text' => 'Install the Android app for your team and run every shoot from the phone with offline support, payments, reminders and team chat.',
            'landing.detail_mobile_cta' => 'Download APK',
            'landing.detail_web_title' => 'Web App',
            'landing.detail_web_text' => 'Open the same studio platform in the browser for easy planning, reports and calendar overviews.',
            'landing.detail_web_cta' => 'Open Web App',
            'landing.detail_team_title' => 'Team & Roles',
            'landing.detail_team_text' => 'Invite managers and freelancers with a 6-digit passcode. Everyone sees exactly the bookings, payouts and permissions their role allows.',
            'landing.detail_team_cta' => 'See Features',
            'landing.detail_finance_title' => 'Built for BDT',
            'landing.detail_finance_text' => 'Bookings, invoices, dues and payouts in Bangladeshi Taka — with bKash, bank transfer and cash all tracked in one finance dashboard.',
            'landing.detail_finance_cta' => 'See Screens',
            'landing.review_1_name' => 'Ayesha Rahman',
            'landing.review_1_role' => 'Studio Owner',
            'landing.review_1_text' => 'Clicker Pro replaced our paper bookings and WhatsApp chaos. Now every shoot is organised and the team knows exactly what to do.',
            'landing.review_2_name' => 'Shakib Hasan',
            'landing.review_2_role' => 'Lead Shooter',
            'landing.review_2_text' => 'The event reminders and finance summary mean I never miss a payment or a shoot date anymore. It feels like the studio finally has one brain.',
            'landing.review_3_name' => 'Nadia Akter',
            'landing.review_3_role' => 'Studio Manager',
            'landing.review_3_text' => 'Our clients love the new invoices and team assignments. Everything looks premium and professional in one place.',
            'app.android_url' => asset('ClickerPro.apk'),
            'app.web_url' => url('/'),
            'app.admin_url' => route('admin.login'),
            // Help & Support contact channels shown in the mobile app. Edit
            // these from the admin Settings page. WhatsApp is a full
            // international number (e.g. 8801XXXXXXXXX) — the app opens a
            // wa.me chat and never displays the raw number to the user.
            'support.email' => 'support@graphy7.app',
            'support.whatsapp' => '',
        ];
    }

    private function isSecret(string $key): bool
    {
        $lower = strtolower($key);
        foreach (self::SECRET_HINTS as $h) {
            if (str_contains($lower, $h)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Admin settings grouped by key prefix ("smtp.fromEmail" → group "smtp").
     * The admin panel renders `{ data: { group: [{key, value, isSecret,
     * hasValue}] } }`; the old flat key→value map crashed the Settings page
     * (`items.map` ran on a string). Secret values are never sent in clear.
     */
    public function index()
    {
        $grouped = [];

        $rows = AppSetting::all()->keyBy('key');
        $defaultSettings = self::getDefaultSettings();
        $allKeys = array_unique(array_merge(array_keys($defaultSettings), $rows->keys()->all()));

        foreach ($allKeys as $key) {
            $row = $rows->get($key);
            $group = str_contains($key, '.') ? explode('.', $key)[0] : 'general';
            $secret = $this->isSecret($key);
            $value = (string) ($row?->value ?? '');
            $default = $defaultSettings[$key] ?? null;

            $grouped[$group][] = [
                'key' => $key,
                'value' => $secret ? '' : $value,
                'defaultValue' => $default,
                'isSecret' => $secret,
                'hasValue' => $value !== '',
            ];
        }

        // Cast to object so an empty result serializes as {} (not []).
        return response()->json(['data' => (object) $grouped]);
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'settings' => 'required|array',
            'settings.*' => 'nullable|string',
        ]);

        foreach ($data['settings'] as $key => $value) {
            // Don't wipe a stored secret when the client sends back the empty
            // masked field — only update secrets when a real value is given.
            if ($this->isSecret((string) $key) && ($value === null || $value === '')) {
                continue;
            }
            AppSetting::updateOrCreate(
                ['key' => $key],
                ['value' => $value]
            );
        }

        return response()->json(['data' => ['ok' => true]]);
    }
}
