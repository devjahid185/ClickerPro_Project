<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Event extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'owner_id', 'client_id', 'package_id', 'title', 'event_type',
        'date', 'venue', 'shift', 'status', 'price', 'advance_paid',
        'due_amount', 'notes', 'internal_notes', 'delivered_at',
        'completed_at', 'sync_status', 'remote_rev',
    ];

    protected $casts = [
        'date' => 'date',
        'price' => 'decimal:2',
        'advance_paid' => 'decimal:2',
        'due_amount' => 'decimal:2',
        'delivered_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function package()
    {
        return $this->belongsTo(Package::class);
    }

    public function assignments()
    {
        return $this->hasMany(Assignment::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    public function invoice()
    {
        return $this->hasOne(Invoice::class);
    }

    public function statusHistories()
    {
        return $this->hasMany(StatusHistory::class);
    }

    public function taskProgresses()
    {
        return $this->hasMany(TaskProgress::class);
    }

    public function reEditRequests()
    {
        return $this->hasMany(ReEditRequest::class);
    }

    public function expenses()
    {
        return $this->hasMany(Expense::class);
    }
}
