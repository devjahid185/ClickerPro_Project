<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    protected $fillable = [
        'owner_id',
        'title',
        'body',
        'pinned',
        'expires_at',
        'read_by',
    ];

    protected $casts = [
        'pinned' => 'boolean',
        'expires_at' => 'datetime',
        'read_by' => 'array',
    ];
}
