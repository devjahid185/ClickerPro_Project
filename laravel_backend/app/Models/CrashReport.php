<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CrashReport extends Model
{
    protected $fillable = [
        'user_id', 'user_role', 'error', 'stack_trace',
        'breadcrumbs', 'platform', 'app_version',
    ];

    protected $casts = [
        'breadcrumbs' => 'array',
    ];
}
