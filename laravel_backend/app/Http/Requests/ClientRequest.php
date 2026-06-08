<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validation for creating/updating a client.
 * Single source of truth — replaces the duplicated rule arrays in
 * ClientController::store and ::update. Name is required on create,
 * optional on update (partial updates).
 */
class ClientRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // behind auth:sanctum; ownership handled in controller
    }

    public function rules(): array
    {
        $creating = $this->isMethod('post');

        return [
            'name' => ($creating ? 'required' : 'nullable') . '|string|max:255',
            'phone' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:255',
            'notes' => 'nullable|string',
        ];
    }
}
