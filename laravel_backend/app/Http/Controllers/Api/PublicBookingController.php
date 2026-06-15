<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\Event;
use App\Models\User;
use Illuminate\Http\Request;

class PublicBookingController extends Controller
{
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

        // Find or create client
        $client = Client::where('owner_id', $owner->id)
            ->where(function ($q) use ($data) {
                $q->where('phone', $data['phone'] ?? '')
                  ->orWhere('email', $data['email'] ?? '');
            })
            ->first();

        if (!$client) {
            $client = Client::create([
                'owner_id' => $owner->id,
                'name' => $data['name'],
                'phone' => $data['phone'] ?? null,
                'email' => $data['email'] ?? null,
            ]);
        }

        $event = Event::create([
            'owner_id' => $owner->id,
            'client_id' => $client->id,
            'package_id' => $data['package_id'] ?? null,
            'title' => ($data['event_type'] ?? 'Booking') . ' - ' . $data['name'],
            'event_type' => $data['event_type'] ?? null,
            'date' => $data['date'],
            'venue' => $data['venue'] ?? null,
            'status' => 'PENDING',
            'notes' => $data['notes'] ?? null,
        ]);

        return response()->json(['data' => $event->load('client')], 201);
    }
}
