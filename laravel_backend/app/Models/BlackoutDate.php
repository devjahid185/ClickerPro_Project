<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BlackoutDate extends Model
{
    protected $fillable = [
        'freelancer_id', 'date', 'end_date', 'reason', 'recurrence',
    ];

    protected $casts = [
        'date' => 'date',
        'end_date' => 'date',
    ];
}
