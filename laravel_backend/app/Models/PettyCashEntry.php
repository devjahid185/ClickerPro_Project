<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PettyCashEntry extends Model
{
    protected $fillable = [
        'owner_id', 'title', 'category', 'amount', 'date', 'note',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'date' => 'date',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }
}
