<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\LogsAudit;
use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Payment;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PaymentController extends Controller
{
    use LogsAudit;

    public function __construct(private PaymentService $payments)
    {
    }

    public function index(Request $request)
    {
        $userId = $request->user()->id;
        $eventIds = Event::where('owner_id', $userId)->pluck('id');

        $q = Payment::whereIn('event_id', $eventIds)
            ->with('event:id,title,client_id', 'event.client:id,name')
            ->orderBy('created_at', 'desc');

        if ($request->kind) $q->where('kind', $request->kind);
        if ($request->method) $q->where('method', $request->method);

        return response()->json(['data' => $q->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'event_id' => 'required|integer|exists:events,id',
            'amount' => 'required|numeric|min:0',
            'kind' => 'required|string|in:ADVANCE,DUE,EXTRA,PAYOUT',
            'method' => 'nullable|string|in:CASH,BKASH,NAGAD,BANK,CARD,OTHER',
            'note' => 'nullable|string',
            'paid_at' => 'nullable|date',
        ]);

        // Authorization: the event must belong to the current user.
        $event = Event::where('owner_id', $request->user()->id)
            ->find($data['event_id']);
        if (!$event) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $payment = $this->payments->record($data, $request->user()->id);

        $this->audit($request, 'CREATE', 'payment', $payment->id, after: [
            'amount' => $payment->amount,
            'kind' => $payment->kind,
            'method' => $payment->method,
            'event_id' => $payment->event_id,
        ]);

        return response()->json(['data' => $payment], 201);
    }

    public function byEvent(Request $request, $eventId)
    {
        // Only the event owner may list its payments.
        $owns = Event::where('owner_id', $request->user()->id)
            ->where('id', $eventId)->exists();
        if (!$owns) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $payments = Payment::where('event_id', $eventId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['data' => $payments]);
    }

    public function update(Request $request, $id)
    {
        $payment = Payment::find($id);
        if (!$payment) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // Ownership: the payment's event must belong to the caller.
        $owns = Event::where('owner_id', $request->user()->id)
            ->where('id', $payment->event_id)->exists();
        if (!$owns) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'amount' => 'nullable|numeric|min:0',
            'kind' => 'nullable|string|in:ADVANCE,DUE,EXTRA,PAYOUT',
            'method' => 'nullable|string|in:CASH,BKASH,NAGAD,BANK,CARD,OTHER',
            'note' => 'nullable|string',
            'paid_at' => 'nullable|date',
        ]);

        $payment = $this->payments->update(
            $payment,
            array_filter($data, fn($v) => $v !== null)
        );

        return response()->json(['data' => $payment]);
    }

    public function destroy(Request $request, $id)
    {
        $payment = Payment::find($id);
        if (!$payment) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $owns = Event::where('owner_id', $request->user()->id)
            ->where('id', $payment->event_id)->exists();
        if (!$owns) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $this->audit($request, 'DELETE', 'payment', $payment->id, before: [
            'amount' => $payment->amount,
            'kind' => $payment->kind,
            'method' => $payment->method,
            'event_id' => $payment->event_id,
        ]);

        $this->payments->delete($payment);

        return response()->json(['message' => 'ok']);
    }

    public function earnings(Request $request)
    {
        $userId = $request->user()->id;

        $eventIds = Event::where('owner_id', $userId)->pluck('id');

        $earnings = Payment::whereIn('event_id', $eventIds)
            ->select('kind', DB::raw('SUM(amount) as total'))
            ->groupBy('kind')
            ->get()
            ->keyBy('kind');

        return response()->json([
            'data' => [
                'ADVANCE' => $earnings->get('ADVANCE')?->total ?? 0,
                'DUE' => $earnings->get('DUE')?->total ?? 0,
                'EXTRA' => $earnings->get('EXTRA')?->total ?? 0,
                'PAYOUT' => $earnings->get('PAYOUT')?->total ?? 0,
                'total' => Payment::whereIn('event_id', $eventIds)->sum('amount'),
            ],
        ]);
    }
}
