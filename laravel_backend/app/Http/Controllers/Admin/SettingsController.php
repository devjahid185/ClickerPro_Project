<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\SettingsController as ApiSettings;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

/**
 * Admin → Settings (Blade). Grouped key/value app settings, reusing the API
 * SettingsController (secrets are masked on read and preserved on save).
 */
class SettingsController extends Controller
{
    public function index(ApiSettings $api)
    {
        // Returns an object keyed by group → [ {key, value, isSecret, hasValue} ]
        $grouped = $api->index()->getData(true)['data'] ?? [];

        return view('admin.settings.index', [
            'groups' => (array) $grouped,
        ]);
    }

    public function update(Request $request, ApiSettings $api)
    {
        // The Blade form posts settings[key] => value; the API expects the
        // same `settings` array. Delegate so secret-preservation logic is shared.
        $api->update($request);

        return back()->with('status', 'Settings saved.');
    }
}
