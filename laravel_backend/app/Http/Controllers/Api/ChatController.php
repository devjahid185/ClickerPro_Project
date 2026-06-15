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

        // Only public sender columns — eager-loading the whole User row
        // would leak manager_permissions, tokens and email to every teammate.
        $messages = ChatMessage::where('group_id', $group->id)
            ->with('sender:id,name,avatar,role')
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

        return response()->json(
            ['data' => $message->load('sender:id,name,avatar,role')],
            201
        );
    }

    /**
     * Marks every message in the group as read by the requester (except the
     * ones they sent). Called when a member opens the thread, so senders can
     * see who has seen their messages.
     */
    public function markRead(Request $request, $groupId)
    {
        $group = $this->authorizedGroup($request, $groupId);
        if (!$group) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $userId = (int) $request->user()->id;
        $messages = ChatMessage::where('group_id', $group->id)
            ->where('sender_id', '!=', $userId)
            ->get();

        foreach ($messages as $message) {
            $readBy = $message->read_by ?? [];
            if (!in_array($userId, array_map('intval', $readBy), true)) {
                $readBy[] = $userId;
                $message->forceFill(['read_by' => $readBy])->save();
            }
        }

        return response()->json(['message' => 'ok']);
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
