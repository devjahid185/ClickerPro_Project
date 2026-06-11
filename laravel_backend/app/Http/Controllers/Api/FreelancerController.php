<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BlackoutDate;
use App\Models\LeaveRequest;
use App\Models\Event;
use App\Models\Payment;
use App\Models\User;
use App\Services\PushService;
use Illuminate\Http\Request;

class FreelancerController extends Controller
{
    /**
     * Freelancer → Owner due-payment request. Strictly app-to-app: the
     * owner gets an in-app push with the freelancer's bKash / bank
     * details. Only works when the freelancer is actually in an
     * owner's team (manager_permissions.ownerId set).
     */
    public function requestPayment(Request $request, PushService $push)
    {
        $data = $request->validate([
            'amount' => 'nullable|numeric|min:0',
            'bkash' => 'nullable|string|max:30',
            'bankDetails' => 'nullable|string|max:255',
            'note' => 'nullable|string|max:500',
        ]);

        $user = $request->user();
        $ownerId = (int) ($user->manager_permissions['ownerId'] ?? 0);
        if (!$ownerId) {
            return response()->json([
                'message' => 'You are not in any owner\'s team yet. Join a team first.',
            ], 422);
        }

        $owner = User::find($ownerId);
        if (!$owner || !$owner->is_active) {
            return response()->json(['message' => 'Owner account not found'], 422);
        }

        $lines = array_filter([
            !empty($data['amount']) ? 'Amount: ৳' . number_format((float) $data['amount']) : null,
            !empty($data['bkash']) ? 'bKash: ' . $data['bkash'] : null,
            !empty($data['bankDetails']) ? 'Bank: ' . $data['bankDetails'] : null,
            !empty($data['note']) ? 'Note: ' . $data['note'] : null,
        ]);

        $sent = $push->sendToUser(
            $ownerId,
            'Due payment request',
            "{$user->name} has requested due payment."
                . ($lines ? "\n" . implode("\n", $lines) : ''),
            [
                'type' => 'payout_request',
                'freelancerId' => (string) $user->id,
                'freelancerName' => (string) $user->name,
            ]
        );

        return response()->json([
            'success' => true,
            'ownerName' => $owner->name,
            'devicesNotified' => $sent,
        ]);
    }

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
