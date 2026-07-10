<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Waitlist extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_id', 'name', 'phone', 'email', 'date_requested', 'notes',
        'facebook_link',
    ];

    protected $casts = [
        'date_requested' => 'date',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }
}
