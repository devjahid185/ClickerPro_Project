<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reminder extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_id', 'event_id', 'type', 'message', 'remind_at', 'sent',
    ];

    protected $casts = [
        'remind_at' => 'datetime',
        'sent' => 'boolean',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function event()
    {
        return $this->belongsTo(Event::class);
    }
}
