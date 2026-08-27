<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

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
        return (int) $request->user()->studioId();
    }

    /** Owner + every linked member in that owner's team. */
    private function teamUserIds(int $ownerId)
    {
        return User::where('id', $ownerId)
            ->orWhereNotNull('manager_permissions')
            ->get(['id', 'manager_permissions'])
            ->filter(function (User $user) use ($ownerId) {
                if ((int) $user->id === $ownerId) {
                    return true;
                }

                $permissions = is_array($user->manager_permissions)
                    ? $user->manager_permissions
                    : [];

                $linkedOwnerId = $permissions['ownerId'] ?? null;
                return $linkedOwnerId !== null && (int) $linkedOwnerId === $ownerId;
            })
            ->pluck('id')
            ->values();
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

        $teamUserIds = $this->teamUserIds((int) $announcement->owner_id);

        foreach ($teamUserIds as $userId) {
            if ((int) $userId === (int) $request->user()->id) {
                continue;
            }

            Notification::create([
                'user_id' => (int) $userId,
                'category' => 'ANNOUNCEMENT',
                'message' => $announcement->title . "\n" . $announcement->body,
                'deeplink' => '/announcements',
            ]);
        }

        // Heads-up push to the team (fail-soft).
        $pushed = app(\App\Services\PushService::class)->sendToUsers(
            $teamUserIds,
            $announcement->title,
            $announcement->body,
            ['type' => 'announcement', 'id' => $announcement->id]
        );
        Log::info('Announcement pushed to team.', [
            'announcement_id' => $announcement->id,
            'owner_id' => $announcement->owner_id,
            'team_user_ids' => $teamUserIds->all(),
            'tokens_attempted' => $pushed,
        ]);

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
