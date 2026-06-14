<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TeamInviteCode;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class TeamController extends Controller
{
    public function getInvite(Request $request)
    {
        $user = $request->user();
        $invite = TeamInviteCode::where('owner_id', $user->id)
            ->where('expires_at', '>', now())
            ->latest()
            ->first();

        return response()->json(['data' => $invite]);
    }

    public function invite(Request $request)
    {
        $user = $request->user();

        // Numbers only — letters in the passcode were hard to share over
        // the phone and easy to mistype.
        $code = (string) random_int(100000, 999999);

        $invite = TeamInviteCode::create([
            'owner_id' => $user->id,
            'code' => $code,
            'expires_at' => now()->addDays(7),
        ]);

        return response()->json(['data' => $invite], 201);
    }

    /**
     * An EXISTING logged-in user joins a team by entering the 6-digit
     * passcode. (acceptInvite in AuthController is for brand-new signups;
     * this is the in-app path.)
     */
    public function join(Request $request)
    {
        $data = $request->validate(['code' => 'required|string']);
        $user = $request->user();

        $invite = TeamInviteCode::where('code', trim($data['code']))
            ->whereNull('used_by')
            ->whereNull('target_email')
            ->latest()
            ->first();

        if (!$invite || ($invite->expires_at && $invite->expires_at->isPast())) {
            return response()->json(['message' => 'Invalid or expired code'], 422);
        }
        if ((int) $invite->owner_id === (int) $user->id) {
            return response()->json(['message' => 'You cannot join your own team'], 422);
        }
        // Only freelancers (and owner-added managers) may join a team. A
        // studio owner / "both" account cannot become someone else's
        // team member.
        if (in_array(strtolower((string) $user->role), ['owner', 'both'], true)) {
            return response()->json(
                ['message' => 'Studio owners cannot join another team. Only freelancers can.'],
                422
            );
        }

        $this->attachToTeam($user, (int) $invite->owner_id);
        $invite->update(['used_by' => $user->id, 'used_at' => now()]);

        return response()->json(['message' => 'ok']);
    }

    /**
     * Owner invites a REGISTERED user by email. The invitee sees the
     * pending invite in-app and confirms — app-to-app, no code typing.
     */
    public function inviteByEmail(Request $request)
    {
        $data = $request->validate(['email' => 'required|email']);
        $owner = $request->user();
        $email = strtolower(trim($data['email']));

        if (strtolower($owner->email) === $email) {
            return response()->json(['message' => 'You cannot invite yourself'], 422);
        }

        $target = User::whereRaw('LOWER(email) = ?', [$email])->first();
        if (!$target) {
            return response()->json(
                ['message' => 'No registered account with this email'],
                422
            );
        }

        // Only freelancers may be added to a team. A studio owner (or a
        // "both" account that runs its own studio) cannot become someone
        // else's team member — that would tangle two studios together.
        if (in_array(strtolower((string) $target->role), ['owner', 'both'], true)) {
            return response()->json(
                ['message' => 'Only freelancers can be added to a team.'],
                422
            );
        }

        $alreadyMember = ((int) ($target->manager_permissions['ownerId'] ?? 0)) === (int) $owner->id;
        if ($alreadyMember) {
            return response()->json(['message' => 'Already in your team'], 422);
        }

        // One live invite per owner+email — refresh instead of stacking.
        TeamInviteCode::where('owner_id', $owner->id)
            ->where('target_email', $email)
            ->whereNull('used_by')
            ->delete();

        $invite = TeamInviteCode::create([
            'owner_id' => $owner->id,
            'code' => (string) random_int(100000, 999999),
            'target_email' => $email,
            'expires_at' => now()->addDays(7),
        ]);

        return response()->json(['data' => $invite], 201);
    }

    /** Pending email invites addressed to the logged-in user. */
    public function pendingInvites(Request $request)
    {
        $email = strtolower($request->user()->email);

        $invites = TeamInviteCode::with('owner:id,name,email')
            ->whereRaw('LOWER(target_email) = ?', [$email])
            ->whereNull('used_by')
            ->where('expires_at', '>', now())
            ->latest()
            ->get()
            ->map(fn (TeamInviteCode $i) => [
                'id' => $i->id,
                'ownerName' => $i->owner?->name ?? 'Studio owner',
                'ownerEmail' => $i->owner?->email,
                'expiresAt' => $i->expires_at,
            ]);

        return response()->json(['data' => $invites]);
    }

    /** Invitee accepts or declines a pending email invite. */
    public function respondInvite(Request $request, $id)
    {
        $data = $request->validate(['accept' => 'required|boolean']);
        $user = $request->user();

        $invite = TeamInviteCode::where('id', $id)
            ->whereRaw('LOWER(target_email) = ?', [strtolower($user->email)])
            ->whereNull('used_by')
            ->first();

        if (!$invite || ($invite->expires_at && $invite->expires_at->isPast())) {
            return response()->json(['message' => 'Invite not found or expired'], 404);
        }

        if ($data['accept']) {
            $this->attachToTeam($user, (int) $invite->owner_id);
        }
        $invite->update(['used_by' => $user->id, 'used_at' => now()]);

        return response()->json(['message' => 'ok']);
    }

    /** Links a user to an owner's team, preserving any permission set. */
    private function attachToTeam(User $user, int $ownerId): void
    {
        $current = $user->manager_permissions ?? [];
        $current['ownerId'] = $ownerId;
        $current['permissions'] = $current['permissions'] ?? [];
        $user->forceFill(['manager_permissions' => $current])->save();
    }

    public function members(Request $request)
    {
        $user = $request->user();
        // The team is anchored to its OWNER: members resolve their
        // owner's id so "My Team" works from both sides of the link.
        $teamOwnerId = (int) ($user->manager_permissions['ownerId'] ?? 0)
            ?: (int) $user->id;

        // Allowlist the fields — raw User rows leak internal columns
        // (manager_permissions, activity metadata) to every teammate.
        //
        // Match on the JSON `ownerId` via the `->>` text-extract operator.
        // `whereJsonContains` does NOT work here: the column is a plain `json`
        // (not jsonb) on Postgres, where containment is unsupported, and it
        // also mis-handled the scalar match on MySQL. `->>` text extraction is
        // supported by BOTH Postgres and MySQL 5.7+, so it is the portable
        // form. We compare as text ('2') because the stored value may be an
        // int or a string depending on which join path wrote it.
        $members = User::where(function ($q) use ($teamOwnerId) {
                $q->where('id', $teamOwnerId)
                  ->orWhereRaw("manager_permissions->>'ownerId' = ?", [(string) $teamOwnerId]);
            })
            ->where('id', '!=', $user->id)
            ->get()
            ->map(fn (User $u) => [
                'id' => $u->id,
                'name' => $u->name,
                'email' => $u->email,
                'phone' => $u->phone,
                'role' => $u->role,
                'avatar' => $u->avatar,
                'created_at' => $u->created_at,
            ])
            ->values();

        return response()->json(['data' => $members]);
    }

    public function updatePermissions(Request $request, $userId)
    {
        $data = $request->validate([
            'permissions' => 'required|array',
        ]);

        $member = User::find($userId);

        if (!$member) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // Authorization: the caller may only edit permissions for members of
        // their OWN team — i.e. members whose manager_permissions.ownerId is the
        // caller. This mirrors how members() scopes the team list. Without this
        // any authenticated user could grant themselves/others elevated
        // permissions on arbitrary accounts.
        $ownerId = $request->user()->id;
        $memberOwnerId = $member->manager_permissions['ownerId'] ?? null;
        // Compare as integers — the stored ownerId may be int or numeric string.
        if ($memberOwnerId === null || (int) $memberOwnerId !== (int) $ownerId) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $current = $member->manager_permissions ?? [];
        $current['permissions'] = $data['permissions'];
        // manager_permissions is a guarded field — set via forceFill.
        $member->forceFill(['manager_permissions' => $current])->save();

        return response()->json(['data' => $member->fresh()]);
    }

    /**
     * Limited member profile for the team owner: name, photo, phone,
     * WhatsApp, own gear list, and finance (payout) summary — and
     * NOTHING else by design.
     */
    public function memberProfile(Request $request, $userId)
    {
        $member = \App\Models\User::find($userId);
        if (!$member) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // Only MY team members — same ownership rule as removeMember.
        $ownerId = $request->user()->id;
        $memberOwnerId = $member->manager_permissions['ownerId'] ?? null;
        if ($memberOwnerId === null || (int) $memberOwnerId !== (int) $ownerId) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $gear = \App\Models\GearItem::where('owner_id', $member->id)
            ->get(['id', 'name', 'category', 'condition']);

        // Finance: this member's assignment payouts within MY events only.
        $myEventIds = \App\Models\Event::where('owner_id', $ownerId)->pluck('id');
        $assignments = \App\Models\Assignment::whereIn('event_id', $myEventIds)
            ->where('user_id', $member->id)
            ->get(['payout', 'payout_paid']);
        $earned = (float) $assignments->sum('payout');
        $paid = (float) $assignments->where('payout_paid', true)->sum('payout');

        return response()->json([
            'data' => [
                'id' => $member->id,
                'name' => $member->name,
                'phone' => $member->phone,
                'avatar' => $member->avatar,
                'role' => $member->role,
                'gear' => $gear,
                'finance' => [
                    'events' => $assignments->count(),
                    'earned' => $earned,
                    'paid' => $paid,
                    'due' => max($earned - $paid, 0),
                ],
            ],
        ]);
    }

    /**
     * Owner-side staff payout sheet: every team member's assignment earnings
     * across the owner's events, with a per-event breakdown so one member
     * working three events shows all three payouts grouped under them.
     *
     * Shape (per member):
     *   { userId, name, avatar, events, earned, paid, due,
     *     items: [{ assignmentId, eventId, eventTitle, date, role,
     *               amount, paid }] }
     */
    public function staffPayouts(Request $request)
    {
        $ownerId = (int) $request->user()->id;
        $eventIds = \App\Models\Event::where('owner_id', $ownerId)->pluck('id');

        $assignments = \App\Models\Assignment::whereIn('event_id', $eventIds)
            ->with(['user:id,name,avatar', 'event:id,title,event_type,date'])
            ->get();

        $members = $assignments
            ->filter(fn ($a) => $a->user !== null)
            ->groupBy('user_id')
            ->map(function ($group) {
                $user = $group->first()->user;
                $earned = (float) $group->sum('payout');
                $paid = (float) $group->where('payout_paid', true)->sum('payout');

                $items = $group->map(fn ($a) => [
                    'assignmentId' => (string) $a->id,
                    'eventId' => (string) $a->event_id,
                    'eventTitle' => $a->event?->title
                        ?? $a->event?->event_type
                        ?? 'Event',
                    'date' => $a->event?->date,
                    'role' => $a->role,
                    'amount' => (float) $a->payout,
                    'paid' => (bool) $a->payout_paid,
                ])->values();

                return [
                    'userId' => (string) $user->id,
                    'name' => $user->name,
                    'avatar' => $user->avatar,
                    'events' => $group->count(),
                    'earned' => $earned,
                    'paid' => $paid,
                    'due' => max($earned - $paid, 0),
                    'items' => $items,
                ];
            })
            ->values();

        return response()->json([
            'data' => [
                'totalEarned' => (float) $assignments->sum('payout'),
                'totalPaid' => (float) $assignments
                    ->where('payout_paid', true)
                    ->sum('payout'),
                'members' => $members,
            ],
        ]);
    }

    /**
     * Marks a team member's outstanding payouts as paid. Pass an optional
     * `assignmentId` to settle a single event; otherwise every unpaid
     * assignment for that member (within the owner's events) is settled.
     */
    public function markPayoutPaid(Request $request, $userId)
    {
        $data = $request->validate([
            'assignmentId' => 'nullable',
        ]);

        $ownerId = (int) $request->user()->id;
        $eventIds = \App\Models\Event::where('owner_id', $ownerId)->pluck('id');

        $query = \App\Models\Assignment::whereIn('event_id', $eventIds)
            ->where('user_id', $userId)
            ->where('payout_paid', false);

        if (!empty($data['assignmentId'])) {
            $query->where('id', $data['assignmentId']);
        }

        $updated = $query->update(['payout_paid' => true]);

        return response()->json(['data' => ['updated' => $updated]]);
    }

    /**
     * Detach a member from the caller's team. The account itself is kept
     * (it may have history elsewhere) — only the team link is severed.
     */
    public function removeMember(Request $request, $userId)
    {
        $member = User::find($userId);

        if (!$member) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // Same ownership rule as updatePermissions: only MY team members.
        $ownerId = $request->user()->id;
        $memberOwnerId = $member->manager_permissions['ownerId'] ?? null;
        if ($memberOwnerId === null || (int) $memberOwnerId !== (int) $ownerId) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $member->forceFill(['manager_permissions' => null])->save();

        return response()->json(['message' => 'ok']);
    }
}
