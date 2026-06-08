<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Event;
use Illuminate\Http\Request;

class InvoiceController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->user()->id;
        $eventIds = Event::where('owner_id', $userId)->pluck('id');

        $q = Invoice::whereIn('event_id', $eventIds)
            ->with('event:id,title,client_id', 'event.client:id,name')
            ->orderBy('created_at', 'desc');

        if ($request->status) $q->where('status', $request->status);

        return response()->json(['data' => $q->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'event_id' => 'required|integer|exists:events,id',
            'subtotal' => 'required|numeric|min:0',
            'tax_rate' => 'nullable|numeric|min:0',
            'tax_amount' => 'nullable|numeric|min:0',
            'total' => 'required|numeric|min:0',
            'notes' => 'nullable|string',
            'language' => 'nullable|string|max:10',
            'status' => 'nullable|string|in:DRAFT,SENT,PAID,OVERDUE',
        ]);

        // Authorization: the event must belong to the current user.
        $owns = Event::where('owner_id', $request->user()->id)
            ->where('id', $data['event_id'])->exists();
        if (!$owns) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data['owner_id'] = $request->user()->id;
        $data['tax_rate'] = $data['tax_rate'] ?? 0;
        $data['tax_amount'] = $data['tax_amount'] ?? 0;
        $data['status'] = $data['status'] ?? 'DRAFT';
        $data['language'] = $data['language'] ?? 'en';

        $invoice = Invoice::create($data);

        return response()->json(['data' => $invoice->load('event')], 201);
    }

    public function show(Request $request, $id)
    {
        $invoice = Invoice::with('event')
            ->where('owner_id', $request->user()->id)
            ->find($id);

        if (!$invoice) {
            return response()->json(['message' => 'Not found'], 404);
        }

        return response()->json(['data' => $invoice]);
    }

    public function byEvent(Request $request, $eventId)
    {
        // Scope to the current user's own events.
        $owns = Event::where('owner_id', $request->user()->id)
            ->where('id', $eventId)->exists();
        if (!$owns) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $invoice = Invoice::with('event')->where('event_id', $eventId)->first();

        if (!$invoice) {
            return response()->json(['message' => 'Not found'], 404);
        }

        return response()->json(['data' => $invoice]);
    }

    public function update(Request $request, $id)
    {
        $invoice = Invoice::where('owner_id', $request->user()->id)->find($id);

        if (!$invoice) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'status' => 'nullable|string|in:DRAFT,SENT,PAID,OVERDUE',
            'subtotal' => 'nullable|numeric|min:0',
            'tax_rate' => 'nullable|numeric|min:0',
            'tax_amount' => 'nullable|numeric|min:0',
            'total' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
            'language' => 'nullable|string|max:10',
            'sent_at' => 'nullable|date',
            'paid_at' => 'nullable|date',
        ]);

        $invoice->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $invoice->fresh()->load('event')]);
    }
}
