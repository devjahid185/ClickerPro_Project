<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\Event;
use App\Policies\EventPolicy;
use Illuminate\Http\Request;

/**
 * Shared event-ownership guard for API controllers.
 * Replaces the copy-pasted private `ownsEvent()` helpers; delegates the
 * actual rule to EventPolicy so authorization lives in one place.
 */
trait ChecksEventOwnership
{
    protected function ownsEvent(Request $request, $eventId): bool
    {
        return (new EventPolicy())->owns($request->user(), (int) $eventId);
    }
}
