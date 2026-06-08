<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Package extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_id', 'name', 'base_price', 'coverage_hours',
        'has_video', 'has_drone', 'has_album', 'notes',
    ];

    protected $casts = [
        'base_price' => 'decimal:2',
        'has_video' => 'boolean',
        'has_drone' => 'boolean',
        'has_album' => 'boolean',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function events()
    {
        return $this->hasMany(Event::class);
    }
}
