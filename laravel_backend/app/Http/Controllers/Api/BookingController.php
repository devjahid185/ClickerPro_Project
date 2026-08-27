<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\LogsAudit;
use App\Http\Controllers\Controller;
use App\Http\Requests\BookingRequest;
use App\Http\Resources\BookingResource;
use App\Models\Event;
use App\Models\Client;
use App\Models\StatusHistory;
use App\Services\GoogleSheetsService;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    use LogsAudit;

    /** Compact booking snapshot stored in the audit trail's before/after. */
    private function auditSnapshot(Event $event): array
    {
        return [
            'title' => $event->title,
            'status' => $event->status,
            'date' => optional($event->date)->toDateString(),
            'venue' => $event->venue,
            'price' => $event->price,
            'due_amount' => $event->due_amount,
        ];
    }

    /**
     * The web/mobile booking form sends a free-text client_name (+ optional
     * phone) rather than a client_id. Resolve it to a Client row owned by the
     * current user — reuse an existing match by name, otherwise create one.
     */
    private function resolveClientId(Request $request, array &$data): void
    {
        $name = trim((string) $request->input('client_name', ''));
        if ($name === '' || !empty($data['client_id'])) {
            return;
        }

        $ownerId = $request->user()->studioId();
        $client = Client::where('owner_id', $ownerId)
            ->whereRaw('LOWER(name) = ?', [strtolower($name)])
            ->first();

        if (!$client) {
            $client = Client::create([
                'owner_id' => $ownerId,
                'name' => $name,
                'phone' => $request->input('client_phone'),
            ]);
        } elseif ($request->filled('client_phone') && !$client->phone) {
            $client->update(['phone' => $request->input('client_phone')]);
        }

        $data['client_id'] = $client->id;
    }

    /**
     * Surface client name/phone at the top level so the frontend can render
     * them directly without digging into the nested client relation.
     */
    /**
     * Shape an event for the API. Delegates to BookingResource so the JSON
     * shape lives in one place; `resolve()` returns the plain array (no extra
     * "data" wrapper) to preserve the existing response structure.
     */
    private function flatten(Event $event): array
    {
        return BookingResource::make($event)->resolve();
    }
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Event::query()
            ->where(function ($q) use ($user) {
                $q->where('owner_id', $user->studioId())
                  ->orWhereHas('assignments', function ($a) use ($user) {
                      $a->where('user_id', $user->id);
                  });
            })
            ->with(['client', 'assignments.user', 'payments', 'package'])
            ->orderBy('date', 'desc');

        // Keep each role's bookings separate. A Freelancer sees only the
        // bookings they created as a freelancer; the Owner view sees OWNER
        // bookings plus legacy rows (booking_context NULL, created before this
        // feature) so nothing already saved disappears. BOTH sees everything.
        $context = $user->bookingContext();
        if ($context === 'FREELANCER') {
            $query->where(function ($q) use ($user) {
                $q->where('booking_context', 'FREELANCER')
                  ->orWhereHas('assignments', function ($a) use ($user) {
                      $a->where('user_id', $user->id);
                  });
            });
        } elseif ($context === 'OWNER') {
            $query->where(function ($q) {
                $q->where('booking_context', 'OWNER')
                  ->orWhereNull('booking_context');
            });
        }

        if ($request->has('status') && $request->status) {
            $query->where('status', $request->status);
        }

        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('venue', 'like', "%{$search}%");
            });
        }

        if ($request->has('limit') && $request->limit) {
            $query->limit((int) $request->limit);
        }

        $events = $query->get()->map(fn ($e) => $this->flatten($e));

        return response()->json(['data' => $events]);
    }

    public function store(BookingRequest $request)
    {
        // Client name/phone are resolved to a client_id below, not stored
        // on the event directly — exclude them from the mass-assigned data.
        $data = collect($request->validated())
            ->except(['client_name', 'client_phone'])
            ->all();

        $data['owner_id'] = $request->user()->studioId();
        // Stamp the role that created this booking so a later role switch keeps
        // it in the right view. BOTH resolves to null → the Owner view (its
        // OR-NULL filter) still shows it, and the Freelancer view hides it.
        $data['booking_context'] = $request->user()->bookingContext() ?? 'OWNER';
        $data['shift'] = $data['shift'] ?? 'DAY';
        $data['status'] = $data['status'] ?? 'PENDING';
        $this->resolveClientId($request, $data);

        // Derive due_amount if not provided
        if (!isset($data['due_amount']) && isset($data['price'])) {
            $data['due_amount'] = $data['price'] - ($data['advance_paid'] ?? 0);
        }

        $event = Event::create($data);

        $this->audit($request, 'CREATE', 'booking', $event->id,
            after: $this->auditSnapshot($event));

        // Auto-append the new booking to the owner's Google Sheet (if the
        // integration is configured). Fail-safe: any Sheets error is swallowed
        // inside the service so it can never block the booking from saving.
        app(GoogleSheetsService::class)->appendBooking($event->load('client'), 'CREATED');

        return response()->json(['data' => $this->flatten($event->load('client'))], 201);
    }


    public function show(Request $request, $id)
    {
        $user = $request->user();
        $event = Event::where(function ($q) use ($user) {
                $q->where('owner_id', $user->studioId())
                  ->orWhereHas('assignments', function ($a) use ($user) {
                      $a->where('user_id', $user->id);
                  });
            })
            ->with(['client', 'assignments.user', 'payments', 'statusHistories', 'package'])
            ->find($id);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        return response()->json(['data' => $this->flatten($event)]);
    }

    public function update(BookingRequest $request, $id)
    {
        $event = Event::where('owner_id', $request->user()->studioId())->find($id);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = collect($request->validated())
            ->except(['client_name', 'client_phone'])
            ->all();

        $this->resolveClientId($request, $data);
        $before = $this->auditSnapshot($event);
        $event->update(array_filter($data, fn($v) => $v !== null));

        $fresh = $event->fresh()->load('client');
        $this->audit($request, 'UPDATE', 'booking', $event->id,
            before: $before, after: $this->auditSnapshot($fresh));
        app(GoogleSheetsService::class)->appendBooking($fresh, 'UPDATED');

        return response()->json(['data' => $this->flatten($fresh)]);
    }

    public function updateStatus(Request $request, $id)
    {
        $user = $request->user();
        $event = Event::where(function ($q) use ($user) {
                $q->where('owner_id', $user->studioId())
                  ->orWhereHas('assignments', function ($a) use ($user) {
                      $a->where('user_id', $user->id);
                  });
            })
            ->find($id);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'status' => 'required|string',
            'note' => 'nullable|string',
        ]);

        // Freelancer rules (Heaven 2026-07-15):
        //  • Their OWN logged booking → may move it to COMPLETED or CANCELLED
        //    (simplified lifecycle — no delivery step for freelancers).
        //  • An assigned studio event → SHOT_COMPLETE only, and only when
        //    actually assigned. One assignee marking the shoot done completes
        //    it for the whole crew.
        if ($user->role === 'FREELANCER') {
            $target = strtoupper($data['status']);
            // A freelancer's own logged booking carries booking_context
            // FREELANCER (stamped at store()); studio events are OWNER/NULL.
            $isOwn = $event->booking_context === 'FREELANCER';
            if ($isOwn && in_array($target, ['COMPLETED', 'CANCELLED'], true)) {
                // allowed — falls through to the chronology guard below
                // (CANCELLED is not post-event, COMPLETED unlocks event-day).
            } elseif ($target === 'SHOT_COMPLETE') {
                $assigned = \App\Models\Assignment::where('event_id', $event->id)
                    ->where('user_id', $user->id)
                    ->exists();
                if (!$assigned) {
                    return response()->json([
                        'message' => 'You are not assigned to this event.',
                    ], 403);
                }
            } else {
                return response()->json([
                    'message' => 'Freelancers can only complete/cancel their own bookings or mark an assigned shoot complete.',
                ], 403);
            }
        }

        // Chronology guard: a shoot can't be "done" before it happens.
        // Post-event statuses unlock from the event DAY onward (the app
        // additionally enforces the end-time on-device).
        $postEvent = ['SHOT_COMPLETE', 'DELIVERED', 'COMPLETED'];
        if (in_array(strtoupper($data['status']), $postEvent, true)
            && $event->date->startOfDay()->gt(now()->startOfDay())) {
            return response()->json([
                'message' => 'Event date is in the future — cannot mark as '
                    . $data['status'] . ' before ' . $event->date->format('d/m/Y'),
            ], 422);
        }

        $oldStatus = $event->status;
        $event->update(['status' => $data['status']]);

        StatusHistory::create([
            'event_id' => $event->id,
            'changed_by' => $request->user()->id,
            'from_status' => $oldStatus,
            'to_status' => $data['status'],
            'note' => $data['note'] ?? null,
        ]);

        $fresh = $event->fresh()->load('client');
        $this->audit($request, 'UPDATE', 'booking', $event->id,
            before: ['status' => $oldStatus],
            after: ['status' => $data['status']]);
        app(GoogleSheetsService::class)->appendBooking($fresh, 'STATUS_UPDATED');

        return response()->json(['data' => $fresh]);
    }

    public function destroy(Request $request, $id)
    {
        $event = Event::where('owner_id', $request->user()->studioId())->find($id);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $before = $this->auditSnapshot($event);
        $event->delete();

        $this->audit($request, 'DELETE', 'booking', $id, before: $before);

        return response()->json(['message' => 'ok']);
    }
}
