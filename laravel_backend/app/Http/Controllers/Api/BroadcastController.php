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
        // The admin composer sends `content`/`audience` (and the optional
        // presentation fields); normalise those to the stored columns before
        // validating so a broadcast actually saves with its full content.
        $this->normalizeBroadcastInput($request);

        $data = $request->validate([
            'title' => 'required|string|max:255',
            'body' => 'required|string',
            'target_role' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'scheduled_at' => 'nullable|date',
            'priority' => 'nullable|string|max:50',
            'type' => 'nullable|string|max:50',
            'image_url' => 'nullable|string|max:1000',
            'link' => 'nullable|string|max:1000',
            'button_label' => 'nullable|string|max:100',
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

        $this->normalizeBroadcastInput($request);

        $data = $request->validate([
            'title' => 'nullable|string|max:255',
            'body' => 'nullable|string',
            'target_role' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'scheduled_at' => 'nullable|date',
            'priority' => 'nullable|string|max:50',
            'type' => 'nullable|string|max:50',
            'image_url' => 'nullable|string|max:1000',
            'link' => 'nullable|string|max:1000',
            'button_label' => 'nullable|string|max:100',
        ]);

        $broadcast->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => new BroadcastResource($broadcast->fresh())]);
    }

    /**
     * Maps the admin composer's client-side field names onto the stored
     * columns: content→body, audience→target_role, imageUrl→image_url,
     * buttonLabel→button_label, and the status alias (ACTIVE/ARCHIVED)→is_active.
     */
    private function normalizeBroadcastInput(Request $request): void
    {
        if ($request->filled('content') && !$request->filled('body')) {
            $request->merge(['body' => $request->input('content')]);
        }
        if ($request->filled('audience') && !$request->filled('target_role')) {
            $aud = strtolower((string) $request->input('audience'));
            $request->merge(['target_role' => $aud === 'all' ? null : $aud]);
        }
        if ($request->has('imageUrl')) {
            $request->merge(['image_url' => $request->input('imageUrl')]);
        }
        if ($request->has('buttonLabel')) {
            $request->merge(['button_label' => $request->input('buttonLabel')]);
        }
        if ($request->filled('status')) {
            $request->merge(['is_active' => strtoupper((string) $request->input('status')) === 'ACTIVE']);
        }
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
