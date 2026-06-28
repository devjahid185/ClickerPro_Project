<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Web-guard counterpart to AdminMiddleware (which guards the API).
 *
 * Redirects non-admins to the login screen instead of returning a 403 JSON
 * body, since the admin console is a server-rendered Blade app.
 */
class AdminWebMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        if (! Auth::check() || Auth::user()->role !== 'ADMIN') {
            Auth::logout();
            return redirect()->route('admin.login')
                ->with('error', 'Admin access required.');
        }
        return $next($request);
    }
}
