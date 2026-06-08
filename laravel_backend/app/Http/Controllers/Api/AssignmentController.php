<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\ChecksEventOwnership;
use App\Models\Assignment;
use Illuminate\Http\Request;

class AssignmentController extends Controller
{
    use ChecksEventOwnership;

    public function index(Request $request, $eventId)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $assignments = Assignment::where('event_id', $eventId)
            ->with('user')
            ->get();

        return response()->json(['data' => $assignments]);
    }

    public function store($eventId, Request $request)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'role' => 'nullable|string|max:100',
            'payout' => 'nullable|numeric|min:0',
            'payout_paid' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        $data['event_id'] = $eventId;

        $assignment = Assignment::create($data);

        return response()->json(['data' => $assignment->load('user')], 201);
    }

    public function update($eventId, $id, Request $request)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $assignment = Assignment::where('event_id', $eventId)->find($id);

        if (!$assignment) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'role' => 'nullable|string|max:100',
            'payout' => 'nullable|numeric|min:0',
            'payout_paid' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        $assignment->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $assignment->fresh()->load('user')]);
    }

    public function destroy($eventId, $id, Request $request)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $assignment = Assignment::where('event_id', $eventId)->find($id);

        if (!$assignment) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $assignment->delete();

        return response()->json(['message' => 'ok']);
    }
}
