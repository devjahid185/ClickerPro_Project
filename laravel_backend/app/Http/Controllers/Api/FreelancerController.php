<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Assignment;
use App\Models\BlackoutDate;
use App\Models\Checkin;
use App\Models\Event;
use App\Models\LeaveRequest;
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
    /**
     * Freelancer earnings: a freelancer earns through ASSIGNMENT payouts on
     * the events they are booked on — NOT through Payment rows (those are the
     * client→owner cash flow). The old version queried events the freelancer
     * *owns* (always none for a pure freelancer), so the screen was always
     * empty. This rebuilds the full overview the dashboard expects: totals,
     * per-owner breakdown, pending list, and a 6-month chart.
     */
    public function earnings(Request $request)
    {
        $userId = $request->user()->id;

        // Every assignment for this freelancer, joined to its event + owner,
        // so we can group payouts by the studio owner who booked them.
        $assignments = \App\Models\Assignment::where('user_id', $userId)
            ->with(['event:id,owner_id,date,event_type,title', 'event.owner:id,name,phone'])
            ->get();

        $earned = (float) $assignments->sum('payout');
        $received = (float) $assignments->where('payout_paid', true)->sum('payout');
        $pending = max($earned - $received, 0);

        // ── Per-owner breakdown (FL-02) ──
        $owners = $assignments
            ->filter(fn ($a) => $a->event && $a->event->owner)
            ->groupBy(fn ($a) => $a->event->owner_id)
            ->map(function ($group) {
                $owner = $group->first()->event->owner;
                $ownerEarned = (float) $group->sum('payout');
                $ownerPaid = (float) $group->where('payout_paid', true)->sum('payout');
                $lastPaid = $group->where('payout_paid', true)
                    ->max(fn ($a) => optional($a->event)->date);

                return [
                    'ownerId' => (string) $owner->id,
                    'ownerName' => $owner->name,
                    'eventsCount' => $group->count(),
                    'earnedAmount' => $ownerEarned,
                    'pendingAmount' => max($ownerEarned - $ownerPaid, 0),
                    'lastPaymentDate' => $lastPaid,
                ];
            })
            ->values();

        // ── Pending payments per owner (FL-03) ──
        $pendingPayments = $assignments
            ->where('payout_paid', false)
            ->filter(fn ($a) => $a->event && $a->event->owner)
            ->groupBy(fn ($a) => $a->event->owner_id)
            ->map(function ($group) {
                $owner = $group->first()->event->owner;
                $oldest = $group->min(fn ($a) => optional($a->event)->date);
                $days = $oldest
                    ? max(now()->diffInDays(\Illuminate\Support\Carbon::parse($oldest)), 0)
                    : 0;

                return [
                    'ownerId' => (string) $owner->id,
                    'ownerName' => $owner->name,
                    'ownerPhone' => $owner->phone ?? '',
                    'amount' => (float) $group->sum('payout'),
                    'pendingDays' => (int) $days,
                ];
            })
            ->values();

        // ── Per-event unpaid payouts ("কোন কোন ইভেন্টের পেমেন্ট পাবে") ──
        $pendingEvents = $assignments
            ->where('payout_paid', false)
            ->filter(fn ($a) => $a->event)
            ->map(function ($a) {
                return [
                    'eventId' => (string) $a->event_id,
                    'eventTitle' => $a->event->title
                        ?? $a->event->event_type
                        ?? 'Event',
                    'date' => $a->event->date,
                    'ownerName' => optional($a->event->owner)->name ?? '',
                    'role' => $a->role,
                    'amount' => (float) $a->payout,
                ];
            })
            ->sortBy('date')
            ->values();

        // ── 6-month chart + yearly recap (FL-04) ──
        $monthly = [];
        for ($i = 5; $i >= 0; $i--) {
            $m = now()->copy()->subMonths($i);
            $amount = (float) $assignments
                ->filter(fn ($a) => optional($a->event)->date &&
                    \Illuminate\Support\Carbon::parse($a->event->date)->isSameMonth($m))
                ->sum('payout');
            $monthly[] = ['month' => $m->format('M'), 'amount' => $amount];
        }
        $bestMonth = collect($monthly)->sortByDesc('amount')->first();
        $bestOwner = $owners->sortByDesc('earnedAmount')->first();

        return response()->json([
            'data' => [
                'totalEarnings' => $earned,
                'receivedAmount' => $received,
                'pendingAmount' => $pending,
                'owners' => $owners,
                'pendingPayments' => $pendingPayments,
                'pendingEvents' => $pendingEvents,
                'yearlyRecap' => [
                    'monthly' => $monthly,
                    'bestMonth' => ($bestMonth && $bestMonth['amount'] > 0)
                        ? $bestMonth
                        : null,
                    'bestOwner' => $bestOwner
                        ? [
                            'ownerName' => $bestOwner['ownerName'],
                            'totalEarned' => $bestOwner['earnedAmount'],
                            'eventsCount' => $bestOwner['eventsCount'],
                        ]
                        : null,
                ],
            ],
        ]);
    }

    // ─── Multi-Owner Dashboard (FL-08) ──────────────────────────────

    /**
     * Every event this freelancer is assigned to, across all studio owners.
     */
    public function dashboardEvents(Request $request)
    {
        $userId = $request->user()->id;

        $assignments = Assignment::where('user_id', $userId)
            ->with(['event:id,owner_id,title,event_type,date,shift,venue,status,start_time,end_time',
                    'event.owner:id,name,business_name'])
            ->get()
            ->filter(fn ($a) => $a->event !== null);

        $events = $assignments->map(function ($a) {
            $start = $a->event->start_time;
            $end = $a->event->end_time;
            $timeSlot = trim((string) $start) !== ''
                ? trim($start . ($end ? ' – ' . $end : ''))
                : '';
            return [
                'assignmentId' => (string) $a->id,
                'eventId' => (string) $a->event->id,
                'title' => $a->event->title ?? $a->event->event_type ?? 'Event',
                'eventType' => $a->event->event_type,
                'date' => $a->event->date,
                'shift' => $a->event->shift,
                'venue' => $a->event->venue,
                'status' => $a->event->status,
                'role' => $a->role,
                'ownerName' => $a->event->owner?->name,
                // Mobile FL-08 dashboard also reads these:
                'companyName' => $a->event->owner?->business_name
                    ?? $a->event->owner?->name,
                'startTime' => $start,
                'timeSlot' => $timeSlot,
            ];
        })->values();

        return response()->json(['data' => $events]);
    }

    /**
     * Overlap warnings: two assigned events on the same date whose shifts
     * clash (BOTH overlaps everything; otherwise same shift clashes).
     */
    public function dashboardConflicts(Request $request)
    {
        $userId = $request->user()->id;

        $assignments = Assignment::where('user_id', $userId)
            ->with(['event:id,title,event_type,date,shift'])
            ->get()
            ->filter(fn ($a) => $a->event !== null)
            ->groupBy(fn ($a) => \Illuminate\Support\Carbon::parse($a->event->date)->toDateString());

        $clash = fn ($x, $y) => $x === 'BOTH' || $y === 'BOTH' || $x === $y;

        $conflicts = [];
        foreach ($assignments as $date => $group) {
            $list = $group->values();
            for ($i = 0; $i < $list->count(); $i++) {
                for ($j = $i + 1; $j < $list->count(); $j++) {
                    $a = $list[$i];
                    $b = $list[$j];
                    if ($clash($a->event->shift, $b->event->shift)) {
                        $conflicts[] = [
                            'date' => $date,
                            'first' => [
                                'eventId' => (string) $a->event->id,
                                'title' => $a->event->title ?? $a->event->event_type ?? 'Event',
                                'shift' => $a->event->shift,
                            ],
                            'second' => [
                                'eventId' => (string) $b->event->id,
                                'title' => $b->event->title ?? $b->event->event_type ?? 'Event',
                                'shift' => $b->event->shift,
                            ],
                        ];
                    }
                }
            }
        }

        return response()->json(['data' => $conflicts]);
    }

    // ─── Live Check-In (FL-09) ──────────────────────────────────────

    /**
     * Records (or updates) the freelancer's check-in for an event. Mirrors
     * the mobile FlCheckin shape (camelCase) on the way back.
     */
    public function checkin(Request $request)
    {
        $data = $request->validate([
            'eventId' => 'required',
            'checkinTime' => 'nullable|date',
            'expectedTime' => 'nullable|date',
            'status' => 'nullable|string|in:checkedIn,late,missed',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        $userId = $request->user()->id;

        // Only allow check-in for an event the freelancer is actually on.
        $isAssigned = Assignment::where('user_id', $userId)
            ->where('event_id', $data['eventId'])
            ->exists();
        if (!$isAssigned) {
            return response()->json(['message' => 'Not assigned to this event'], 403);
        }

        $checkin = Checkin::updateOrCreate(
            ['user_id' => $userId, 'event_id' => $data['eventId']],
            [
                'checkin_time' => $data['checkinTime'] ?? now(),
                'expected_time' => $data['expectedTime'] ?? null,
                'status' => $data['status'] ?? 'checkedIn',
                'latitude' => $data['latitude'] ?? null,
                'longitude' => $data['longitude'] ?? null,
            ],
        );

        return response()->json(['data' => $this->checkinShape($checkin)], 201);
    }

    /**
     * Returns the freelancer's check-in status for one event, or null data.
     */
    public function checkinStatus(Request $request, $eventId)
    {
        $checkin = Checkin::where('user_id', $request->user()->id)
            ->where('event_id', $eventId)
            ->first();

        return response()->json([
            'data' => $checkin ? $this->checkinShape($checkin) : null,
        ]);
    }

    private function checkinShape(Checkin $c): array
    {
        return [
            'id' => (string) $c->id,
            'remoteId' => (string) $c->id,
            'freelancerId' => (string) $c->user_id,
            'eventId' => (string) $c->event_id,
            'checkinTime' => optional($c->checkin_time)->toIso8601String(),
            'expectedTime' => optional($c->expected_time)->toIso8601String(),
            'status' => $c->status,
            'latitude' => $c->latitude !== null ? (float) $c->latitude : null,
            'longitude' => $c->longitude !== null ? (float) $c->longitude : null,
            'createdAt' => optional($c->created_at)->toIso8601String(),
        ];
    }
}
