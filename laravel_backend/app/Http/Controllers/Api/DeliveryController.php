<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\StatusHistory;
use Illuminate\Http\Request;

class DeliveryController extends Controller
{
    public function update(Request $request, $eventId)
    {
        $event = Event::where('owner_id', $request->user()->id)->find($eventId);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'delivered_at' => 'nullable|date',
            'note' => 'nullable|string',
        ]);

        $oldStatus = $event->status;
        $event->update([
            'delivered_at' => $data['delivered_at'] ?? now(),
            'status' => 'DELIVERED',
        ]);

        StatusHistory::create([
            'event_id' => $event->id,
            'changed_by' => $request->user()->id,
            'from_status' => $oldStatus,
            'to_status' => 'DELIVERED',
            'note' => $data['note'] ?? null,
        ]);

        return response()->json(['data' => $event->fresh()]);
    }
}
