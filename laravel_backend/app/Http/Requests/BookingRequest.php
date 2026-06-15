<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validation for creating/updating a booking (event).
 * Single source of truth — replaces the duplicated rule arrays that lived
 * in BookingController::store and ::update.
 *
 * On create (POST) title and date are required; on update (PATCH/PUT) all
 * fields are optional so partial updates work. The controller still reads
 * the free-text client_name/client_phone directly to resolve the client.
 */
class BookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Route is already behind auth:sanctum; per-resource ownership is
        // enforced in the controller. Allow the validated request through.
        return true;
    }

    public function rules(): array
    {
        $creating = $this->isMethod('post');
        $req = fn (string $r) => $creating ? "required|$r" : "nullable|$r";

        return [
            'title' => $req('string|max:255'),
            'date' => $req('date'),
            'client_id' => 'nullable|integer|exists:clients,id',
            'package_id' => 'nullable|integer|exists:packages,id',
            'event_type' => 'nullable|string|max:100',
            'venue' => 'nullable|string|max:255',
            'shift' => 'nullable|string|in:DAY,NIGHT,BOTH',
            'status' => 'nullable|string',
            'price' => 'nullable|numeric',
            'advance_paid' => 'nullable|numeric',
            'due_amount' => 'nullable|numeric',
            'notes' => 'nullable|string',
            'internal_notes' => 'nullable|string',
            // Free-text client fields the controller resolves to a client_id.
            'client_name' => 'nullable|string|max:255',
            'client_phone' => 'nullable|string|max:30',
            // Rich detail fields (mobile↔web parity).
            'company_name' => 'nullable|string|max:255',
            'bride_name' => 'nullable|string|max:255',
            'groom_name' => 'nullable|string|max:255',
            'outdoor' => 'nullable|boolean',
            'outdoor_location' => 'nullable|string|max:255',
            'reporting_time' => 'nullable|string|max:50',
            'start_time' => 'nullable|string|max:50',
            'end_time' => 'nullable|string|max:50',
            'map_link' => 'nullable|string|max:1000',
            'coverage_hours' => 'nullable|numeric',
            'extra_hour_rate' => 'nullable|numeric',
            'custom_price' => 'nullable|numeric',
            'drive_link' => 'nullable|string|max:1000',
            'requirements_note' => 'nullable|string',
            'chief_photographer_name' => 'nullable|string|max:255',
            'hide_payment_from_team' => 'nullable|boolean',
            'show_payment_in_share' => 'nullable|boolean',
        ];
    }
}
