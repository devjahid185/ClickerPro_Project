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
        foreach (AppSetting::all() as $row) {
            $key = (string) $row->key;
            $group = str_contains($key, '.') ? explode('.', $key)[0] : 'general';
            $secret = $this->isSecret($key);
            $value = (string) ($row->value ?? '');

            $grouped[$group][] = [
                'key' => $key,
                'value' => $secret ? '' : $value,
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
