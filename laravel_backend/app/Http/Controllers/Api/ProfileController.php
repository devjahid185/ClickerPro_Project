<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        return response()->json(['data' => new UserResource($request->user())]);
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:30',
            'bio' => 'nullable|string',
            'staff_position' => 'nullable|string|max:100',
            'business_name' => 'nullable|string|max:255',
            'avatar' => 'nullable|string',
            // Studio logo + digital signature (remote URL or base64 data-URI).
            'logo_url' => 'nullable|string',
            'signature_url' => 'nullable|string',
            // Payout details so a team owner can see how to pay this member.
            'bkash_number' => 'nullable|string|max:30',
            'bank_details' => 'nullable|string|max:500',
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
        if (!in_array($requested, ['OWNER', 'FREELANCER', 'BOTH', 'OFFICE_STAFF'], true)) {
            return response()->json(['message' => 'Invalid role'], 422);
        }

        $user = $request->user();
        // role is guarded — set explicitly for this validated flow.
        $user->forceFill(['role' => $requested])->save();

        return response()->json(['data' => ['user' => new UserResource($user->fresh())]]);
    }
}
