<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatGroup;
use App\Models\ChatMessage;
use Illuminate\Http\Request;

/**
 * Team chat. Membership is DERIVED from the team link, never stored:
 * everyone whose manager_permissions.ownerId points at an owner (plus
 * the owner) shares that owner's chat groups. Joining the team is
 * joining the chat — no separate "add to chat" step exists.
 */
class ChatController extends Controller
{
    /** The chat scope: own id for owners, the owner's id for members. */
    private function teamOwnerId(Request $request): int
    {
        $user = $request->user();
        $ownerId = (int) ($user->manager_permissions['ownerId'] ?? 0);
        return $ownerId ?: (int) $user->id;
    }

    public function groups(Request $request)
    {
        $ownerId = $this->teamOwnerId($request);

        $groups = ChatGroup::where('owner_id', $ownerId)
            ->orderBy('name')
            ->get();

        // First open: nobody has created a group yet. Auto-create the
        // default Team Chat so the screen is never dead-empty.
        if ($groups->isEmpty()) {
            $groups = collect([
                ChatGroup::create(['owner_id' => $ownerId, 'name' => 'Team Chat']),
            ]);
        }

        return response()->json(['data' => $groups]);
    }

    public function createGroup(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
        ]);

        // Groups always belong to the TEAM (the owner's scope), even when
        // a manager creates one — otherwise it would be invisible to
        // everyone else.
        $group = ChatGroup::create([
            'name' => $data['name'],
            'owner_id' => $this->teamOwnerId($request),
        ]);

        return response()->json(['data' => $group], 201);
    }

    public function messages(Request $request, $groupId)
    {
        $group = $this->authorizedGroup($request, $groupId);
        if (!$group) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $messages = ChatMessage::where('group_id', $group->id)
            ->with('sender')
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json(['data' => $messages]);
    }

    public function sendMessage(Request $request, $groupId)
    {
        $group = $this->authorizedGroup($request, $groupId);
        if (!$group) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'body' => 'required|string',
        ]);

        $message = ChatMessage::create([
            'group_id' => $group->id,
            'sender_id' => $request->user()->id,
            'body' => $data['body'],
        ]);

        return response()->json(['data' => $message->load('sender')], 201);
    }

    /** A group is accessible iff it belongs to the requester's team. */
    private function authorizedGroup(Request $request, $groupId): ?ChatGroup
    {
        $group = ChatGroup::find($groupId);
        if (!$group) {
            return null;
        }
        return ((int) $group->owner_id) === $this->teamOwnerId($request)
            ? $group
            : null;
    }
}
