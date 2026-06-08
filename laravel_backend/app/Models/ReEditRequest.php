<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReEditRequest extends Model
{
    use HasFactory;

    protected $table = 're_edit_requests';

    protected $fillable = [
        'event_id', 'requested_by', 'description', 'status', 'admin_note',
    ];

    public function event()
    {
        return $this->belongsTo(Event::class);
    }

    public function requestedBy()
    {
        return $this->belongsTo(User::class, 'requested_by');
    }
}
