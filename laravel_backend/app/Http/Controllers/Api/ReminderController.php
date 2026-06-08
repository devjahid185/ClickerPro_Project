<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reminder;
use Illuminate\Http\Request;

class ReminderController extends Controller
{
    public function index(Request $request)
    {
        $reminders = Reminder::where('owner_id', $request->user()->id)
            ->orderBy('remind_at', 'asc')
            ->get();

        return response()->json(['data' => $reminders]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'event_id' => 'nullable|integer|exists:events,id',
            'type' => 'required|string|max:100',
            'message' => 'required|string',
            'remind_at' => 'required|date',
        ]);

        $data['owner_id'] = $request->user()->id;
        $data['sent'] = false;

        $reminder = Reminder::create($data);

        return response()->json(['data' => $reminder], 201);
    }

    public function destroy(Request $request, $id)
    {
        $reminder = Reminder::where('owner_id', $request->user()->id)->find($id);

        if (!$reminder) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $reminder->delete();

        return response()->json(['message' => 'ok']);
    }
}
