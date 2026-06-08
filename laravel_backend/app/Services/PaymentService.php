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

        return DB::transaction(function () use ($data) {
            $payment = Payment::create($data);

            $event = Event::find($data['event_id']);
            if ($event) {
                if ($data['kind'] === 'ADVANCE') {
                    $event->increment('advance_paid', $data['amount']);
                } elseif ($data['kind'] === 'DUE') {
                    $event->decrement('due_amount', $data['amount']);
                }
            }

            return $payment;
        });
    }
}
