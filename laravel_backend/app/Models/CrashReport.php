<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CrashReport extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected $fillable = [
        'user_id', 'user_role', 'error', 'stack_trace',
        'breadcrumbs', 'platform', 'app_version', 'resolved_at',
    ];

    protected $casts = [
        'breadcrumbs' => 'array',
        'resolved_at' => 'datetime',
    ];
}
