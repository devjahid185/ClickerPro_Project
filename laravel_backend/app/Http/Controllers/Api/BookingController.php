<?php

namespace App\Http\Controllers\Api;

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

        $ownerId = $request->user()->id;
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
        $query = Event::where('owner_id', $request->user()->id)
            ->with('client')
            ->orderBy('date', 'desc');

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

        $data['owner_id'] = $request->user()->id;
        $data['shift'] = $data['shift'] ?? 'DAY';
        $data['status'] = $data['status'] ?? 'PENDING';
        $this->resolveClientId($request, $data);

        // Derive due_amount if not provided
        if (!isset($data['due_amount']) && isset($data['price'])) {
            $data['due_amount'] = $data['price'] - ($data['advance_paid'] ?? 0);
        }

        $event = Event::create($data);

        // Auto-append the new booking to the owner's Google Sheet (if the
        // integration is configured). Fail-safe: any Sheets error is swallowed
        // inside the service so it can never block the booking from saving.
        $this->syncBookingToSheet($event->load('client'));

        return response()->json(['data' => $this->flatten($event->load('client'))], 201);
    }

    /**
     * Append a flat row for [$event] to the configured Google Sheet. No-op when
     * the integration is disabled. Column order is documented in
     * GOOGLE_SHEETS_SETUP.md so the sheet header can match.
     */
    private function syncBookingToSheet(Event $event): void
    {
        $sheets = app(GoogleSheetsService::class);
        if (!$sheets->isEnabled()) {
            return;
        }

        $sheets->appendRow([
            $event->id,
            optional($event->created_at)->toDateTimeString(),
            $event->title,
            $event->event_type,
            optional($event->client)->name,
            optional($event->client)->phone,
            $event->date,
            $event->shift,
            $event->venue,
            $event->status,
            $event->price,
            $event->advance_paid,
            $event->due_amount,
        ], (string) config('services.google_sheets.tab', 'Bookings'));
    }

    public function show(Request $request, $id)
    {
        $event = Event::where('owner_id', $request->user()->id)
            ->with(['client', 'assignments.user', 'payments', 'statusHistories', 'package'])
            ->find($id);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        return response()->json(['data' => $this->flatten($event)]);
    }

    public function update(BookingRequest $request, $id)
    {
        $event = Event::where('owner_id', $request->user()->id)->find($id);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = collect($request->validated())
            ->except(['client_name', 'client_phone'])
            ->all();

        $this->resolveClientId($request, $data);
        $event->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $this->flatten($event->fresh()->load('client'))]);
    }

    public function updateStatus(Request $request, $id)
    {
        $event = Event::where('owner_id', $request->user()->id)->find($id);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'status' => 'required|string',
            'note' => 'nullable|string',
        ]);

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

        return response()->json(['data' => $event->fresh()]);
    }

    public function destroy(Request $request, $id)
    {
        $event = Event::where('owner_id', $request->user()->id)->find($id);

        if (!$event) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $event->delete();

        return response()->json(['message' => 'ok']);
    }
}
