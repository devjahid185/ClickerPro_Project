<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Explicit allowlist serializer for the authenticated user.
 *
 * SECURITY (M1): auth/profile endpoints previously returned the raw User model,
 * which auto-exposes every column (and any future column) including internal
 * fields like manager_permissions, ip_address/user_agent/last_activity. This
 * resource returns ONLY the fields the clients actually need.
 *
 * Notes:
 * - `public_booking_token` is intentionally included: it is the user's OWN
 *   public booking link, which the Settings screen needs to display. Exposing
 *   a user's own token to that same user is not a leak.
 * - camelCase aliases are included because the web app reads camelCase while
 *   the Flutter app reads snake_case; both consume this same payload.
 * - password / totp_secret are never present (model $hidden + not listed here).
 */
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $teamOwnerId = is_array($this->manager_permissions)
            ? ($this->manager_permissions['ownerId'] ?? null)
            : null;
        $teamOwnerId = $teamOwnerId === null ? null : (int) $teamOwnerId;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            // WhatsApp contact (snake_case + camelCase aliases).
            'whatsapp' => $this->whatsapp,
            'role' => $this->role,
            'plan' => $this->plan,
            'is_active' => (bool) $this->is_active,

            // Team/studio link for managers and freelancers. Owner/BOTH users
            // resolve their studio to their own id; linked teammates resolve to
            // the owner account they joined via team invite.
            'owner_id' => $teamOwnerId,
            'ownerId' => $teamOwnerId,
            'studio_id' => $this->studioId(),
            'studioId' => $this->studioId(),

            // Business profile (snake_case + camelCase aliases for both clients)
            'business_name' => $this->business_name,
            'businessName' => $this->business_name,
            // Studio address + specialization (persisted device-side fields).
            'studio_address' => $this->studio_address,
            'studioAddress' => $this->studio_address,
            'specialization' => $this->specialization,
            'bio' => $this->bio,
            'avatar' => $this->avatar,

            // Payout details (needed so re-login can restore what was saved).
            'bkash_number' => $this->bkash_number,
            'bkashNumber' => $this->bkash_number,
            'bank_details' => $this->bank_details,
            'bankDetails' => $this->bank_details,

            // Office staff position (Photo Editor / HR / Office Boy / …)
            'staff_position' => $this->staff_position,
            'staffPosition' => $this->staff_position,

            // Studio logo + digital signature (snake_case + camelCase aliases).
            'logo_url' => $this->logo_url,
            'logoUrl' => $this->logo_url,
            'signature_url' => $this->signature_url,
            'signatureUrl' => $this->signature_url,

            // Studio money settings (snake_case + camelCase aliases).
            'currency_code' => $this->currency_code,
            'currencyCode' => $this->currency_code,
            'vat_enabled' => (bool) $this->vat_enabled,
            'vatEnabled' => (bool) $this->vat_enabled,
            'vat_rate_pct' => $this->vat_rate_pct === null
                ? null
                : (float) $this->vat_rate_pct,
            'vatRatePct' => $this->vat_rate_pct === null
                ? null
                : (float) $this->vat_rate_pct,
            'vat_label' => $this->vat_label,
            'vatLabel' => $this->vat_label,
            'vat_bin' => $this->vat_bin,
            'vatBin' => $this->vat_bin,

            // Owner's own public booking link (needed by Settings).
            'public_booking_token' => $this->public_booking_token,
            'publicToken' => $this->public_booking_token,
            'bookingToken' => $this->public_booking_token,

            // 2FA enabled flag is safe to expose (the secret is not).
            'totp_enabled' => (bool) $this->totp_enabled,

            'created_at' => $this->created_at,
        ];
    }
}
