<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\SecurityController as ApiSecurity;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

/**
 * Admin → Security (Blade). Login activity + blocked-IP management, reusing
 * the API SecurityController.
 */
class SecurityController extends Controller
{
    public function index(ApiSecurity $api)
    {
        $activity = $api->loginActivity(request())->getData(true)['data'] ?? [];
        $blocked  = $api->blockedIps()->getData(true)['data'] ?? [];

        return view('admin.security.index', [
            'activity' => $activity,
            'blocked'  => $blocked,
        ]);
    }

    public function blockIp(Request $request, ApiSecurity $api)
    {
        $request->validate(['ip' => ['required', 'string', 'max:45']]);
        $api->blockIp($request);
        return back()->with('status', "IP {$request->ip} blocked.");
    }

    public function unblockIp($ip, ApiSecurity $api)
    {
        $api->unblockIp($ip);
        return back()->with('status', "IP {$ip} unblocked.");
    }
}
