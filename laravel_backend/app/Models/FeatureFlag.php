<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeatureFlag extends Model
{
    use HasFactory;

    protected $fillable = [
        'key', 'label', 'requires_pro', 'is_enabled',
    ];

    protected $casts = [
        'requires_pro' => 'boolean',
        'is_enabled' => 'boolean',
    ];
}
