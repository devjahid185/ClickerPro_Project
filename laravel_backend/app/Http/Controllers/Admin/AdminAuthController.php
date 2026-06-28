<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Session-based auth for the Laravel admin console (web guard).
 *
 * This is separate from the API's Sanctum token flow: the admin panel is a
 * server-rendered Blade app, so it uses a standard web session + CSRF rather
 * than a Bearer token in localStorage. Only ADMIN-role users may sign in.
 */
class AdminAuthController extends Controller
{
    public function showLogin()
    {
        if (Auth::check() && Auth::user()->role === 'ADMIN') {
            return redirect()->route('admin.dashboard');
        }
        return view('admin.auth.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        // Gate on the ADMIN role explicitly — a valid OWNER/FREELANCER must
        // never reach the console even with correct credentials.
        if (! Auth::attempt($credentials, $request->boolean('remember'))) {
            return back()
                ->withInput($request->only('email'))
                ->with('error', 'Invalid email or password.');
        }

        if (Auth::user()->role !== 'ADMIN') {
            Auth::logout();
            return back()
                ->withInput($request->only('email'))
                ->with('error', 'This account does not have admin access.');
        }

        $request->session()->regenerate();
        return redirect()->intended(route('admin.dashboard'));
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('admin.login');
    }
}
