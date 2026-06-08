<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GearItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_id', 'name', 'category', 'serial_number',
        'condition', 'purchase_value', 'notes', 'is_available',
    ];

    protected $casts = [
        'purchase_value' => 'decimal:2',
        'is_available' => 'boolean',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function rentRecords()
    {
        return $this->hasMany(RentRecord::class);
    }
}
