<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\Event;
use App\Models\PublicBookingRequest;
use App\Models\User;
use App\Services\PushService;
use Illuminate\Http\Request;

class PublicBookingController extends Controller
{
    public function __construct(private PushService $push)
    {
    }

    public function show($token)
    {
        $owner = User::where('public_booking_token', $token)->first();

        if (!$owner) {
            return response()->json(['message' => 'Invalid booking link'], 404);
        }

        $packages = $owner->packages()->get();

        return response()->json([
            'data' => [
                'studio' => [
                    'name' => $owner->business_name ?? $owner->name,
                    'bio' => $owner->bio,
                    // Prefer the studio logo; fall back to the avatar photo.
                    'avatar' => $owner->logo_url ?: $owner->avatar,
                    'logo_url' => $owner->logo_url,
                ],
                'packages' => $packages,
            ],
        ]);
    }

    /**
     * Visitor submits a booking request. This creates a PENDING request —
     * NOT an event — so the owner reviews it before it becomes a booking.
     */
    public function store(Request $request, $token)
    {
        $owner = User::where('public_booking_token', $token)->first();

        if (!$owner) {
            return response()->json(['message' => 'Invalid booking link'], 404);
        }

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:255',
            'event_type' => 'nullable|string|max:100',
            'date' => 'required|date',
            'venue' => 'nullable|string|max:255',
            'package_id' => 'nullable|integer|exists:packages,id',
            'notes' => 'nullable|string',
        ]);

        $data['owner_id'] = $owner->id;
        $item = PublicBookingRequest::create($data);

        $this->push->sendToUser(
            $owner->id,
            'New booking request',
            $data['name'] . ' requested a booking for ' . $data['date'],
            ['type' => 'public_booking_request', 'request_id' => (string) $item->id],
        );

        return response()->json(['data' => $item], 201);
    }

    /** Owner: pending requests for the current studio. */
    public function index(Request $request)
    {
        $items = PublicBookingRequest::where('owner_id', $request->user()->id)
            ->where('status', PublicBookingRequest::STATUS_PENDING)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['data' => $items]);
    }

    /** Owner: approve a request — promotes it to a PENDING event. */
    public function approve(Request $request, $id)
    {
        $item = PublicBookingRequest::where('owner_id', $request->user()->id)
            ->where('status', PublicBookingRequest::STATUS_PENDING)
            ->find($id);

        if (!$item) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // Find or create the client by phone/email.
        $client = null;
        if ($item->phone || $item->email) {
            $client = Client::where('owner_id', $item->owner_id)
                ->where(function ($q) use ($item) {
                    $q->where('phone', $item->phone ?? '')
                      ->orWhere('email', $item->email ?? '');
                })
                ->first();
        }

        if (!$client) {
            $client = Client::create([
                'owner_id' => $item->owner_id,
                'name' => $item->name,
                'phone' => $item->phone,
                'email' => $item->email,
            ]);
        }

        $event = Event::create([
            'owner_id' => $item->owner_id,
            'client_id' => $client->id,
            'package_id' => $item->package_id,
            'title' => ($item->event_type ?? 'Booking') . ' - ' . $item->name,
            'event_type' => $item->event_type,
            'date' => $item->date,
            'venue' => $item->venue,
            'status' => 'PENDING',
            'notes' => $item->notes,
        ]);

        $item->update([
            'status' => PublicBookingRequest::STATUS_APPROVED,
            'event_id' => $event->id,
        ]);

        return response()->json(['data' => $event->load('client')]);
    }

    /** Owner: reject a request. */
    public function reject(Request $request, $id)
    {
        $item = PublicBookingRequest::where('owner_id', $request->user()->id)
            ->where('status', PublicBookingRequest::STATUS_PENDING)
            ->find($id);

        if (!$item) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $item->update(['status' => PublicBookingRequest::STATUS_REJECTED]);

        return response()->json(['data' => $item->fresh()]);
    }
}
