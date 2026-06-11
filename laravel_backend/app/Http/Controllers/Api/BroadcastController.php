<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BroadcastResource;
use App\Models\Broadcast;
use Illuminate\Http\Request;

class BroadcastController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $broadcasts = Broadcast::where('is_active', true)
            ->where(function ($q) use ($user) {
                $q->whereNull('target_role')
                  ->orWhere('target_role', $user->role);
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['data' => BroadcastResource::collection($broadcasts)]);
    }

    public function trackView($id)
    {
        $broadcast = Broadcast::find($id);
        if (!$broadcast) {
            return response()->json(['message' => 'Not found'], 404);
        }
        $broadcast->increment('view_count');
        return response()->json(['message' => 'ok']);
    }

    public function trackClick($id)
    {
        $broadcast = Broadcast::find($id);
        if (!$broadcast) {
            return response()->json(['message' => 'Not found'], 404);
        }
        $broadcast->increment('click_count');
        return response()->json(['message' => 'ok']);
    }

    public function adminIndex(Request $request)
    {
        $broadcasts = Broadcast::orderBy('created_at', 'desc')->get();
        return response()->json(['data' => BroadcastResource::collection($broadcasts)]);
    }

    public function adminStore(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'body' => 'required|string',
            'target_role' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'scheduled_at' => 'nullable|date',
        ]);

        $data['created_by'] = $request->user()->id;
        $data['is_active'] = $data['is_active'] ?? true;

        $broadcast = Broadcast::create($data);

        // Push the broadcast to every registered device. Fail-soft: a
        // push hiccup must never fail the admin's create request.
        if ($broadcast->is_active) {
            app(\App\Services\PushService::class)->sendToAll(
                $broadcast->title,
                $broadcast->body,
                ['type' => 'broadcast', 'id' => $broadcast->id]
            );
        }

        return response()->json(['data' => new BroadcastResource($broadcast)], 201);
    }

    public function adminUpdate(Request $request, $id)
    {
        $broadcast = Broadcast::find($id);

        if (!$broadcast) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'title' => 'nullable|string|max:255',
            'body' => 'nullable|string',
            'target_role' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'scheduled_at' => 'nullable|date',
        ]);

        $broadcast->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => new BroadcastResource($broadcast->fresh())]);
    }

    public function adminDestroy($id)
    {
        $broadcast = Broadcast::find($id);

        if (!$broadcast) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $broadcast->delete();

        return response()->json(['message' => 'ok']);
    }
}
