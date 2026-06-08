<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;

class ExtraTimeController extends Controller
{
    public function store(Request $request, $eventId)
    {
        $event = Event::where('owner_id', $request->user()->id)->find($eventId);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'extra_hours' => 'required|numeric|min:0',
            'note' => 'nullable|string',
        ]);

        $noteEntry = '[Extra Time: ' . $data['extra_hours'] . ' hours]';
        if (isset($data['note'])) {
            $noteEntry .= ' ' . $data['note'];
        }

        $existing = $event->internal_notes ?? '';
        $event->update([
            'internal_notes' => trim($existing . "\n" . $noteEntry),
        ]);

        return response()->json(['data' => $event->fresh()]);
    }
}
