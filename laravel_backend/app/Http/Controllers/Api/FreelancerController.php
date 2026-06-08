<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BlackoutDate;
use App\Models\LeaveRequest;
use App\Models\Event;
use App\Models\Payment;
use Illuminate\Http\Request;

class FreelancerController extends Controller
{
    // ── Blackout / unavailable dates ──
    public function blackouts(Request $request)
    {
        $items = BlackoutDate::where('freelancer_id', $request->user()->id)
            ->orderBy('date')
            ->get();

        return response()->json(['data' => $items]);
    }

    public function storeBlackout(Request $request)
    {
        $data = $request->validate([
            'date' => 'required|date',
            'end_date' => 'nullable|date',
            'reason' => 'nullable|string|max:255',
            'recurrence' => 'nullable|string|in:none,weekly,monthly,yearly',
        ]);
        $data['freelancer_id'] = $request->user()->id;
        $data['recurrence'] = $data['recurrence'] ?? 'none';

        $item = BlackoutDate::create($data);
        return response()->json(['data' => $item], 201);
    }

    public function destroyBlackout(Request $request, $id)
    {
        $item = BlackoutDate::where('freelancer_id', $request->user()->id)->find($id);
        if (!$item) return response()->json(['message' => 'Not found'], 404);
        $item->delete();
        return response()->json(['message' => 'ok']);
    }

    // ── Leave requests ──
    public function leaves(Request $request)
    {
        $items = LeaveRequest::where('freelancer_id', $request->user()->id)
            ->orderBy('start_date', 'desc')
            ->get();

        return response()->json(['data' => $items]);
    }

    public function storeLeave(Request $request)
    {
        $data = $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date',
            'reason' => 'required|string|max:255',
            'notes' => 'nullable|string',
            'owner_id' => 'nullable|integer|exists:users,id',
        ]);
        $data['freelancer_id'] = $request->user()->id;
        $data['status'] = 'PENDING';

        $item = LeaveRequest::create($data);
        return response()->json(['data' => $item], 201);
    }

    public function updateLeave(Request $request, $id)
    {
        $item = LeaveRequest::where('freelancer_id', $request->user()->id)->find($id);
        if (!$item) return response()->json(['message' => 'Not found'], 404);

        $data = $request->validate([
            'status' => 'nullable|string|in:PENDING,APPROVED,REJECTED',
            'reason' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
        ]);
        $item->update(array_filter($data, fn ($v) => $v !== null));
        return response()->json(['data' => $item->fresh()]);
    }

    public function destroyLeave(Request $request, $id)
    {
        $item = LeaveRequest::where('freelancer_id', $request->user()->id)->find($id);
        if (!$item) return response()->json(['message' => 'Not found'], 404);
        $item->delete();
        return response()->json(['message' => 'ok']);
    }

    // ── Work history (derived from this user's bookings) ──
    public function workHistory(Request $request)
    {
        $userId = $request->user()->id;
        $events = Event::where('owner_id', $userId)
            ->with('client:id,name')
            ->orderBy('date', 'desc')
            ->limit(100)
            ->get()
            ->map(fn ($e) => [
                'id' => (string) $e->id,
                'title' => $e->title,
                'date' => $e->date,
                'status' => $e->status,
                'venue' => $e->venue,
                'price' => (float) $e->price,
                'clientName' => $e->client?->name,
            ]);

        return response()->json(['data' => $events]);
    }

    // ── Earnings summary (freelancer dashboard) ──
    public function earnings(Request $request)
    {
        $userId = $request->user()->id;
        $eventIds = Event::where('owner_id', $userId)->pluck('id');

        $byKind = Payment::whereIn('event_id', $eventIds)
            ->selectRaw('kind, SUM(amount) as total')
            ->groupBy('kind')->pluck('total', 'kind');

        $received = (float) ($byKind['PAYOUT'] ?? 0);
        $total = (float) Payment::whereIn('event_id', $eventIds)->sum('amount');

        return response()->json([
            'data' => [
                'totalEarnings' => $total,
                'receivedAmount' => $received,
                'pendingAmount' => max($total - $received, 0),
                'advance' => (float) ($byKind['ADVANCE'] ?? 0),
                'due' => (float) ($byKind['DUE'] ?? 0),
                'extra' => (float) ($byKind['EXTRA'] ?? 0),
                'payout' => $received,
            ],
        ]);
    }
}
