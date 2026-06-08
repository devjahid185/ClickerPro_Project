<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\Event;
use App\Models\Payment;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function search(Request $request)
    {
        $q = $request->get('q', '');
        $userId = $request->user()->id;

        if (!$q) {
            return response()->json(['data' => ['events' => [], 'clients' => [], 'payments' => []]]);
        }

        $events = Event::where('owner_id', $userId)
            ->where(function ($query) use ($q) {
                $query->where('title', 'like', "%{$q}%")
                      ->orWhere('venue', 'like', "%{$q}%");
            })
            ->limit(10)
            ->get();

        $clients = Client::where('owner_id', $userId)
            ->where(function ($query) use ($q) {
                $query->where('name', 'like', "%{$q}%")
                      ->orWhere('email', 'like', "%{$q}%");
            })
            ->limit(10)
            ->get();

        $eventIds = Event::where('owner_id', $userId)->pluck('id');
        $payments = Payment::whereIn('event_id', $eventIds)
            ->where('note', 'like', "%{$q}%")
            ->limit(10)
            ->get();

        return response()->json([
            'data' => [
                'events' => $events,
                'clients' => $clients,
                'payments' => $payments,
            ],
        ]);
    }
}
