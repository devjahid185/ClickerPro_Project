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
        // Rich detail fields (mobile↔web parity).
        'company_name', 'bride_name', 'groom_name', 'outdoor',
        'outdoor_location', 'reporting_time', 'start_time', 'end_time',
        'map_link', 'coverage_hours', 'extra_hour_rate', 'custom_price',
        'drive_link', 'requirements_note', 'chief_photographer_name',
        'hide_payment_from_team', 'show_payment_in_share',
    ];

    protected $casts = [
        'date' => 'date',
        'price' => 'decimal:2',
        'advance_paid' => 'decimal:2',
        'due_amount' => 'decimal:2',
        'delivered_at' => 'datetime',
        'completed_at' => 'datetime',
        'outdoor' => 'boolean',
        'hide_payment_from_team' => 'boolean',
        'show_payment_in_share' => 'boolean',
        'coverage_hours' => 'decimal:2',
        'extra_hour_rate' => 'decimal:2',
        'custom_price' => 'decimal:2',
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
