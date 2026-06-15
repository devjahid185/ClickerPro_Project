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

        // Clients match by name, email AND phone number.
        $clients = Client::where('owner_id', $userId)
            ->where(function ($query) use ($q) {
                $query->where('name', 'like', "%{$q}%")
                      ->orWhere('email', 'like', "%{$q}%")
                      ->orWhere('phone', 'like', "%{$q}%");
            })
            ->limit(10)
            ->get();

        // The query may be a date ("2026-06-15", "15/06/2026", "june 15").
        $parsedDate = null;
        try {
            $normalized = preg_match('#^\d{1,2}/\d{1,2}/\d{4}$#', $q)
                ? str_replace('/', '-', $q) // d/m/Y → d-m-Y so Carbon reads day-first
                : $q;
            $parsedDate = \Illuminate\Support\Carbon::parse($normalized)->toDateString();
        } catch (\Throwable $e) {
            // Not a date — fine.
        }

        // Events match by title, venue, date, or the matched clients
        // (so searching a phone number / client / company name finds
        // their events too).
        $clientIds = $clients->pluck('id');
        $events = Event::where('owner_id', $userId)
            ->where(function ($query) use ($q, $parsedDate, $clientIds) {
                $query->where('title', 'like', "%{$q}%")
                      ->orWhere('venue', 'like', "%{$q}%");
                if ($parsedDate) {
                    $query->orWhereDate('date', $parsedDate);
                }
                if ($clientIds->isNotEmpty()) {
                    $query->orWhereIn('client_id', $clientIds);
                }
            })
            ->orderBy('date', 'desc')
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
