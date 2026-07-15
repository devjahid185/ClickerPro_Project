<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();

        // Accounts created before public self-booking have a NULL
        // public_booking_token, which made the share link + client booking
        // form dead ("লিংক শেয়ার ও করা যায় না" — Heaven 2026-07-15).
        // Backfill it on demand so every account always has a working link.
        if (empty($user->public_booking_token)) {
            $user->forceFill([
                'public_booking_token' => (string) \Illuminate\Support\Str::uuid(),
            ])->save();
        }

        return response()->json(['data' => new UserResource($user)]);
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:30',
            // WhatsApp number for client contact; kept separate from phone.
            'whatsapp' => 'nullable|string|max:30',
            'bio' => 'nullable|string',
            'staff_position' => 'nullable|string|max:100',
            'business_name' => 'nullable|string|max:255',
            // Studio address + specialization — persisted so they survive logout.
            'studio_address' => 'nullable|string|max:500',
            'specialization' => 'nullable|string|max:120',
            'avatar' => 'nullable|string',
            // Studio logo + digital signature (remote URL or base64 data-URI).
            'logo_url' => 'nullable|string',
            'signature_url' => 'nullable|string',
            // Payout details so a team owner can see how to pay this member.
            'bkash_number' => 'nullable|string|max:30',
            'bank_details' => 'nullable|string|max:500',
            // Studio money settings (currency + tax), shared across devices/web.
            'currency_code' => 'nullable|string|size:3',
            'vat_enabled' => 'nullable|boolean',
            'vat_rate_pct' => 'nullable|numeric|min:0|max:999.99',
            'vat_label' => 'nullable|string|max:20',
            // Tax identification number (BIN) printed on invoices.
            'vat_bin' => 'nullable|string|max:50',
        ]);

        $user = $request->user();
        $user->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => new UserResource($user->fresh())]);
    }

    /**
     * Switch between the self-service roles. ADMIN/MANAGER are privileged
     * and can never be reached through this endpoint.
     */
    public function changeRole(Request $request)
    {
        $data = $request->validate([
            'newRole' => 'nullable|string',
            'role' => 'nullable|string',
        ]);

        $requested = strtoupper($data['newRole'] ?? $data['role'] ?? '');
        if (!in_array($requested, ['OWNER', 'FREELANCER', 'BOTH'], true)) {
            return response()->json(['message' => 'Invalid role'], 422);
        }

        $user = $request->user();
        // role is guarded — set explicitly for this validated flow.
        $user->forceFill(['role' => $requested])->save();

        return response()->json(['data' => ['user' => new UserResource($user->fresh())]]);
    }
}
