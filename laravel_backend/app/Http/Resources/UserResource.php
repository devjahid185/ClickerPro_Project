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
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role,
            'plan' => $this->plan,
            'is_active' => (bool) $this->is_active,

            // Business profile (snake_case + camelCase aliases for both clients)
            'business_name' => $this->business_name,
            'businessName' => $this->business_name,
            'bio' => $this->bio,
            'avatar' => $this->avatar,

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
