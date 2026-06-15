<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Broadcast extends Model
{
    use HasFactory;

    protected $fillable = [
        'created_by', 'title', 'body', 'target_role',
        'is_active', 'scheduled_at', 'view_count', 'click_count',
        'priority', 'type', 'image_url', 'link', 'button_label',
        'times_per_day',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'scheduled_at' => 'datetime',
        'times_per_day' => 'integer',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
