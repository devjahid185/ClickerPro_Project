<?php

namespace App\Policies;

use App\Models\Event;
use App\Models\User;

/**
 * Authorization rules for events (bookings). Centralizes the ownership
 * check that was previously duplicated as `ownsEvent()` across controllers.
 */
class EventPolicy
{
    // NOTE: intentionally no `before()` admin override — preserves the exact
    // pre-refactor behavior (ownership was checked uniformly). Admin-wide
    // access, if ever desired, should be added deliberately, not by default.

    public function view(User $user, Event $event): bool
    {
        return (int) $event->owner_id === $user->studioId();
    }

    public function update(User $user, Event $event): bool
    {
        return (int) $event->owner_id === $user->studioId();
    }

    public function delete(User $user, Event $event): bool
    {
        return (int) $event->owner_id === $user->studioId();
    }

    /**
     * Convenience for "can this user act on event id X" given only the id.
     * Scoped by studio (owner account), not the literal caller id, so a
     * manager/freelancer working inside the studio can act on the owner's
     * events — matching how the mobile app already scopes bookings locally.
     */
    public function owns(User $user, int $eventId): bool
    {
        return Event::where('id', $eventId)
            ->where('owner_id', $user->studioId())
            ->exists();
    }
}
