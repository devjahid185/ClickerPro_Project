<?php

namespace App\Services;

use App\Models\Event;
use App\Models\Payment;
use Illuminate\Support\Facades\DB;

/**
 * Encapsulates payment recording + the side effect on the event's running
 * balance. Extracted from PaymentController to keep the controller thin and
 * the money logic in one testable place. Behavior is identical to before;
 * the create + balance update are now wrapped in a DB transaction so they
 * can never partially apply.
 */
class PaymentService
{
    /**
     * Record a payment against an event and adjust its balance.
     *
     * @param array $data validated payment fields (event_id, amount, kind, …)
     * @param int   $recordedBy current user id
     */
    public function record(array $data, int $recordedBy): Payment
    {
        $data['recorded_by'] = $recordedBy;
        $data['method'] = $data['method'] ?? 'CASH';

        $payment = DB::transaction(function () use ($data) {
            $payment = Payment::create($data);
            $this->syncEventBalance((int) $data['event_id']);

            return $payment;
        });

        app(GoogleSheetsService::class)->appendPayment($payment->fresh()->load('event.client'), 'CREATED');

        return $payment;
    }

    /**
     * Update a payment's fields and re-apply its effect on the event
     * balance (reverse the old amounts, apply the new ones) atomically.
     */
    public function update(Payment $payment, array $data): Payment
    {
        $payment = DB::transaction(function () use ($payment, $data) {
            $payment->update($data);
            $payment->refresh();
            $this->syncEventBalance((int) $payment->event_id);

            return $payment;
        });

        app(GoogleSheetsService::class)->appendPayment($payment->fresh()->load('event.client'), 'UPDATED');

        return $payment;
    }

    /**
     * Delete a payment and roll its effect back out of the event balance.
     */
    public function delete(Payment $payment): void
    {
        $snapshot = $payment->fresh()->load('event.client');

        DB::transaction(function () use ($payment) {
            $eventId = (int) $payment->event_id;
            $payment->delete();
            $this->syncEventBalance($eventId);
        });

        app(GoogleSheetsService::class)->appendPayment($snapshot, 'DELETED');
    }

    private function syncEventBalance(int $eventId): void
    {
        $event = Event::find($eventId);
        if (!$event) {
            return;
        }

        $advance = (float) Payment::where('event_id', $eventId)
            ->where('kind', 'ADVANCE')
            ->sum('amount');
        $receivedAgainstBooking = (float) Payment::where('event_id', $eventId)
            ->whereIn('kind', ['ADVANCE', 'DUE', 'PAID'])
            ->sum('amount');
        $price = (float) $event->price;

        $event->forceFill([
            'advance_paid' => $advance,
            'due_amount' => max($price - $receivedAgainstBooking, 0),
        ])->save();
    }
}
