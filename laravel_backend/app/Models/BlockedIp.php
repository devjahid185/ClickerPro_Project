<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BlockedIp extends Model
{
    use HasFactory;

    protected $table = 'blocked_ips';

    protected $fillable = [
        'ip', 'reason', 'blocked_at',
    ];

    protected $casts = [
        'blocked_at' => 'datetime',
    ];
}
