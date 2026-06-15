<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Package extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_id', 'name', 'base_price', 'coverage_hours',
        'has_video', 'has_drone', 'has_album', 'notes', 'meta',
    ];

    protected $casts = [
        'base_price' => 'decimal:2',
        'has_video' => 'boolean',
        'has_drone' => 'boolean',
        'has_album' => 'boolean',
        'meta' => 'array',
    ];

    // Flatten the JSON `meta` bag onto the top-level package JSON so the
    // client reads `price`, `discount`, `photographers`, etc. directly.
    protected $appends = ['extended'];

    public function getExtendedAttribute(): array
    {
        return is_array($this->meta) ? $this->meta : [];
    }

    public function toArray()
    {
        $base = parent::toArray();
        $meta = is_array($this->meta) ? $this->meta : [];
        unset($base['meta'], $base['extended']);
        // Top-level meta keys win where they exist (price, discount, counts…).
        return array_merge($base, $meta);
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function events()
    {
        return $this->hasMany(Event::class);
    }
}
