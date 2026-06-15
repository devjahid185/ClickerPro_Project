<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Serializer for platform broadcasts.
 *
 * Unifies the response shape across all clients. The Flutter app and the
 * dashboard BroadcastBanner read `content` / `createdAt` (and optional
 * priority/type/link/buttonLabel/imageUrl); the admin panel reads the same.
 * The DB stores `body` / `created_at` / `is_active`, so we expose both the
 * raw columns and the client-facing aliases. This mirrors the shape already
 * produced by AdminController-style mapping, so admin/web/Flutter all agree.
 */
class BroadcastResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'title' => $this->title,

            // body ↔ content alias (clients read `content`)
            'body' => $this->body,
            'content' => $this->body ?? '',

            // optional presentation fields (not all columns exist; safe defaults)
            'priority' => $this->priority ?? 'Normal',
            'type' => $this->type ?? 'Announcement',
            // Absolutise the image path so mobile/web can load it directly.
            // Uploads come back as "/storage/uploads/…"; prefix the app host
            // when it isn't already an absolute http(s) URL.
            'imageUrl' => $this->absoluteUrl($this->image_url),
            'image_url' => $this->absoluteUrl($this->image_url),
            'link' => $this->link ?? null,
            'buttonLabel' => $this->button_label ?? null,
            'timesPerDay' => (int) ($this->times_per_day ?? 1),
            'times_per_day' => (int) ($this->times_per_day ?? 1),

            // targeting + status (snake + camel)
            'target_role' => $this->target_role,
            'targetRole' => $this->target_role,
            'is_active' => (bool) $this->is_active,
            // Admin panel reads ACTIVE / ARCHIVED (uppercase) for its badge
            // and Archive/Activate toggle.
            'status' => $this->is_active ? 'ACTIVE' : 'ARCHIVED',

            'scheduled_at' => $this->scheduled_at,
            'view_count' => $this->view_count,
            'click_count' => $this->click_count,

            // created_at ↔ createdAt alias (clients read `createdAt`)
            'created_at' => $this->created_at,
            'createdAt' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * Turns a stored path into an absolute URL. Leaves already-absolute
     * http(s) URLs untouched; prefixes the app host for "/storage/…" paths.
     */
    private function absoluteUrl(?string $path): ?string
    {
        $p = trim((string) $path);
        if ($p === '') {
            return null;
        }
        if (preg_match('#^https?://#i', $p)) {
            return $p;
        }
        return url($p);
    }
}
