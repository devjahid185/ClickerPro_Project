<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Followup;
use Illuminate\Http\Request;

class FollowupController extends Controller
{
    public function index(Request $request)
    {
        $followups = Followup::where('owner_id', $request->user()->id)
            ->with('event:id,title')
            ->orderBy('scheduled_date', 'asc')
            ->get();

        return response()->json(['data' => $followups]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'event_id' => 'nullable|integer|exists:events,id',
            'type' => 'nullable|string|in:album,payment,feedback',
            'scheduled_date' => 'required|date',
            'note' => 'nullable|string',
        ]);

        $data['owner_id'] = $request->user()->id;
        $data['type'] = $data['type'] ?? 'payment';

        $followup = Followup::create($data);

        return response()->json(['data' => $followup->fresh()->load('event:id,title')], 201);
    }

    public function update(Request $request, $id)
    {
        $followup = Followup::where('owner_id', $request->user()->id)->find($id);
        if (!$followup) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'type' => 'nullable|string|in:album,payment,feedback',
            'scheduled_date' => 'nullable|date',
            'completed' => 'nullable|boolean',
            'note' => 'nullable|string',
        ]);

        $followup->update(array_filter($data, fn ($v) => $v !== null));

        return response()->json(['data' => $followup->fresh()->load('event:id,title')]);
    }

    public function destroy(Request $request, $id)
    {
        $followup = Followup::where('owner_id', $request->user()->id)->find($id);
        if (!$followup) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $followup->delete();

        return response()->json(['message' => 'ok']);
    }
}
