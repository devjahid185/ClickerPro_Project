<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PublicBookingRequest extends Model
{
    use HasFactory;

    public const STATUS_PENDING = 'PENDING';
    public const STATUS_APPROVED = 'APPROVED';
    public const STATUS_REJECTED = 'REJECTED';

    protected $fillable = [
        'owner_id', 'name', 'phone', 'email', 'event_type', 'date',
        'venue', 'package_id', 'notes', 'status', 'event_id',
    ];

    protected $casts = [
        'date' => 'date',
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
