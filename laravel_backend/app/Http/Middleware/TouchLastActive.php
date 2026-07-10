<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Stamps the authenticated user's `last_active_at` so the admin console can
 * show "last seen" and Active/Inactive status.
 *
 * Throttled: only writes when the stored value is older than 15 minutes, so
 * a burst of API calls doesn't hammer the users table with one UPDATE each.
 * Runs after auth — an unauthenticated request is left untouched.
 */
class TouchLastActive
{
    /** Don't re-write more than once per this window, per user. */
    private const THROTTLE_MINUTES = 15;

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user !== null) {
            $last = $user->last_active_at;
            if ($last === null || $last->diffInMinutes(now()) >= self::THROTTLE_MINUTES) {
                // updateQuietly → skip model events / touch of updated_at, so
                // "last active" tracking never looks like a profile edit.
                $user->forceFill(['last_active_at' => now()])->saveQuietly();
            }
        }

        return $next($request);
    }
}
