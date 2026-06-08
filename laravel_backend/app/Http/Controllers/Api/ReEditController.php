<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\ChecksEventOwnership;
use App\Models\ReEditRequest;
use Illuminate\Http\Request;

class ReEditController extends Controller
{
    use ChecksEventOwnership;

    public function index(Request $request, $eventId)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $requests = ReEditRequest::where('event_id', $eventId)
            ->with('requestedBy')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['data' => $requests]);
    }

    public function store($eventId, Request $request)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'description' => 'required|string',
        ]);

        $reEdit = ReEditRequest::create([
            'event_id' => $eventId,
            'requested_by' => $request->user()->id,
            'description' => $data['description'],
            'status' => 'PENDING',
        ]);

        return response()->json(['data' => $reEdit], 201);
    }

    public function update(Request $request, $id)
    {
        $reEdit = ReEditRequest::find($id);

        if (!$reEdit) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // Only the owner of the parent event may change a re-edit request.
        if (!$this->ownsEvent($request, $reEdit->event_id)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'status' => 'nullable|string|in:PENDING,APPROVED,REJECTED',
            'admin_note' => 'nullable|string',
        ]);

        $reEdit->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $reEdit->fresh()]);
    }
}
