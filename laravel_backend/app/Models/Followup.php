<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Followup extends Model
{
    protected $fillable = [
        'owner_id', 'event_id', 'type', 'scheduled_date', 'completed', 'note',
    ];

    protected $casts = [
        'scheduled_date' => 'date',
        'completed' => 'boolean',
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
