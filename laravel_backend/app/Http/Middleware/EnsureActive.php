<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

// Blocks suspended accounts on EVERY authenticated request, not just at login.
// Suspending a user (is_active=false) must take effect immediately even for an
// already-logged-in session that still holds a valid Sanctum token — otherwise
// the token keeps working until it expires. This runs after `auth:sanctum`, so
// `$request->user()` is the token's owner; a suspended owner is rejected with
// 403 and their tokens are purged so the client is forced to log out.
class EnsureActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && !$user->is_active) {
            // Kill every token so the client can't keep retrying with the same
            // (or another) token; the app treats 403 here as "log out".
            $user->tokens()->delete();

            return response()->json([
                'message' => 'Your account has been suspended. Please contact support.',
                'code' => 'ACCOUNT_SUSPENDED',
            ], 403);
        }

        return $next($request);
    }
}
