<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Broadcast;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * The user's notification inbox: their per-user notifications (self-booking
     * requests, payments, re-edits…) merged with active admin broadcasts, all
     * in the single shape the app's AppNotification.fromJson expects.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $personal = Notification::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get()
            ->map(fn (Notification $n) => $n->toAppJson());

        $broadcasts = Broadcast::where('is_active', true)
            ->where(function ($q) use ($user) {
                $q->whereNull('target_role')
                  ->orWhere('target_role', $user->role);
            })
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get()
            ->map(fn (Broadcast $b) => [
                'id' => 'broadcast-' . $b->id,
                'category' => 'ANNOUNCEMENT',
                'message' => trim(($b->title ? $b->title . ' — ' : '') . $b->body),
                'read' => false,
                'sentAt' => optional($b->created_at)->toIso8601String(),
                'deeplink' => null,
            ]);

        // Newest first across both sources.
        $merged = $personal->concat($broadcasts)
            ->sortByDesc('sentAt')
            ->values();

        return response()->json(['data' => $merged]);
    }

    /**
     * Marks a notification read. Accepts the id either in the path
     * (/notifications/{id}/read) or in the body ({ notificationId }). Broadcast
     * pseudo-ids ("broadcast-…") have no per-user row, so they're a no-op OK.
     */
    public function markRead(Request $request, $id = null)
    {
        $id = $id ?? $request->input('notificationId');

        if ($id !== null && !str_starts_with((string) $id, 'broadcast-')) {
            Notification::where('user_id', $request->user()->id)
                ->whereKey($id)
                ->update(['read_at' => now()]);
        }

        return response()->json(['message' => 'ok']);
    }
}
