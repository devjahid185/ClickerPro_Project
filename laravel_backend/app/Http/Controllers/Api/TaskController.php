<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\ChecksEventOwnership;
use App\Models\TaskProgress;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    use ChecksEventOwnership;

    public function index(Request $request, $eventId)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $tasks = TaskProgress::where('event_id', $eventId)
            ->with('user:id,name,avatar,role')
            ->get();

        return response()->json(['data' => $tasks]);
    }

    public function upsert($eventId, Request $request)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'percentage' => 'required|integer|min:0|max:100',
            'note' => 'nullable|string',
        ]);

        $userId = $request->user()->id;

        $task = TaskProgress::updateOrCreate(
            ['event_id' => $eventId, 'user_id' => $userId],
            ['percentage' => $data['percentage'], 'note' => $data['note'] ?? null]
        );

        return response()->json(['data' => $task->load('user:id,name,avatar,role')]);
    }
}
