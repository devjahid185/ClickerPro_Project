<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * A per-user in-app notification. Serialized to the shape the Flutter app's
 * AppNotification.fromJson expects: { id, category, message, read, sentAt,
 * deeplink }.
 */
class Notification extends Model
{
    protected $fillable = [
        'user_id', 'category', 'message', 'deeplink', 'read_at',
    ];

    protected $casts = [
        'read_at' => 'datetime',
    ];

    /** The app-facing JSON shape (matches AppNotification.fromJson). */
    public function toAppJson(): array
    {
        return [
            'id' => (string) $this->id,
            'category' => $this->category,
            'message' => $this->message,
            'read' => $this->read_at !== null,
            'sentAt' => optional($this->created_at)->toIso8601String(),
            'deeplink' => $this->deeplink,
        ];
    }
}
