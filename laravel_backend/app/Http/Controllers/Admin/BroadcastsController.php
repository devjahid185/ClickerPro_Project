<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\BroadcastController;
use App\Http\Controllers\Controller;
use App\Models\Broadcast;
use Illuminate\Http\Request;

/**
 * Admin → Notifications / Broadcasts (Blade). Create/toggle/delete reuse the
 * API's BroadcastController so the push-on-create side effect stays identical.
 */
class BroadcastsController extends Controller
{
    public const ROLES = ['ALL', 'OWNER', 'FREELANCER', 'BOTH', 'MANAGER'];

    public function index(BroadcastController $api)
    {
        $data = $api->adminIndex(request())->getData(true)['data'] ?? [];

        return view('admin.broadcasts.index', [
            'broadcasts' => $data,
            'roles'      => self::ROLES,
        ]);
    }

    public function store(Request $request, BroadcastController $api)
    {
        // Map the simple Blade form to the fields the API store expects.
        $request->merge([
            'is_active' => $request->boolean('is_active', true),
            'target_role' => $request->input('target_role') === 'ALL'
                ? null
                : $request->input('target_role'),
        ]);
        $resp = $api->adminStore($request);

        if ($resp->getStatusCode() >= 400) {
            return back()->withInput()->with('error', 'Could not create broadcast.');
        }
        return redirect()->route('admin.broadcasts')->with('status', 'Broadcast sent.');
    }

    public function update(Request $request, $id, BroadcastController $api)
    {
        $request->merge([
            'is_active' => $request->boolean('is_active'),
            'target_role' => $request->input('target_role') === 'ALL'
                ? null
                : $request->input('target_role'),
        ]);

        $resp = $api->adminUpdate($request, $id);

        if ($resp->getStatusCode() >= 400) {
            return back()->withInput()->with('error', 'Could not update broadcast.');
        }

        return redirect()->route('admin.broadcasts')->with('status', 'Broadcast updated.');
    }

    public function toggle($id, BroadcastController $api)
    {
        $b = Broadcast::findOrFail($id);
        // Flip active state through the API update path.
        request()->merge(['is_active' => ! $b->is_active]);
        $api->adminUpdate(request(), $id);

        return back()->with('status', 'Broadcast ' . ($b->is_active ? 'archived' : 'activated') . '.');
    }

    public function destroy($id, BroadcastController $api)
    {
        $api->adminDestroy($id);
        return back()->with('status', 'Broadcast deleted.');
    }
}
