<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\Request;

/**
 * Owner→team announcements. The OWNER (or BOTH) creates them; every
 * member of that owner's team — and the owner — sees the same list.
 * Distinct from admin Broadcasts, which are platform-wide.
 */
class AnnouncementController extends Controller
{
    /** The studio scope: a member's owner id, or the user's own id. */
    private function scopeOwnerId(Request $request): int
    {
        $user = $request->user();
        $memberOwner = $user->manager_permissions['ownerId'] ?? null;
        return $memberOwner !== null ? (int) $memberOwner : (int) $user->id;
    }

    public function index(Request $request)
    {
        $items = Announcement::where('owner_id', $this->scopeOwnerId($request))
            ->where(function ($q) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->orderByDesc('pinned')
            ->orderByDesc('created_at')
            ->get();

        return response()->json(['data' => $items]);
    }

    public function store(Request $request)
    {
        // Only the studio owner may publish to the team.
        if ($this->scopeOwnerId($request) !== (int) $request->user()->id) {
            return response()->json(['message' => 'Only the owner can post announcements'], 403);
        }

        $data = $request->validate([
            'title' => 'required|string|max:255',
            'body' => 'required|string',
            'pinned' => 'nullable|boolean',
            'expiresAt' => 'nullable|date',
        ]);

        $announcement = Announcement::create([
            'owner_id' => $request->user()->id,
            'title' => $data['title'],
            'body' => $data['body'],
            'pinned' => $data['pinned'] ?? false,
            'expires_at' => $data['expiresAt'] ?? null,
            'read_by' => [],
        ]);

        // Heads-up push to the whole team (fail-soft).
        app(\App\Services\PushService::class)->sendToAll(
            $announcement->title,
            $announcement->body,
            ['type' => 'announcement', 'id' => $announcement->id]
        );

        return response()->json(['data' => $announcement], 201);
    }

    public function update(Request $request, $id)
    {
        $announcement = Announcement::where('owner_id', $request->user()->id)->find($id);
        if (!$announcement) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'title' => 'nullable|string|max:255',
            'body' => 'nullable|string',
            'pinned' => 'nullable|boolean',
            'expiresAt' => 'nullable|date',
        ]);

        $announcement->update(array_filter([
            'title' => $data['title'] ?? null,
            'body' => $data['body'] ?? null,
            'pinned' => $data['pinned'] ?? null,
            'expires_at' => $data['expiresAt'] ?? null,
        ], fn ($v) => $v !== null));

        return response()->json(['data' => $announcement->fresh()]);
    }

    public function destroy(Request $request, $id)
    {
        $announcement = Announcement::where('owner_id', $request->user()->id)->find($id);
        if (!$announcement) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $announcement->delete();

        return response()->json(['message' => 'ok']);
    }

    /** Any team member marks it read — their id joins read_by. */
    public function markRead(Request $request, $id)
    {
        $announcement = Announcement::where('owner_id', $this->scopeOwnerId($request))->find($id);
        if (!$announcement) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $readBy = $announcement->read_by ?? [];
        $uid = (string) $request->user()->id;
        if (!in_array($uid, array_map('strval', $readBy), true)) {
            $readBy[] = $uid;
            $announcement->update(['read_by' => $readBy]);
        }

        return response()->json(['data' => $announcement->fresh()]);
    }
}
