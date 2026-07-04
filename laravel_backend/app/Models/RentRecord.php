<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RentRecord extends Model
{
    use HasFactory;

    protected $fillable = [
        'gear_item_id', 'owner_id', 'direction', 'rented_to',
        'counterparty_phone', 'amount', 'rented_at', 'return_by',
        'returned_at', 'notes',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'rented_at' => 'datetime',
        'return_by' => 'datetime',
        'returned_at' => 'datetime',
    ];

    public function gearItem()
    {
        return $this->belongsTo(GearItem::class);
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }
}
