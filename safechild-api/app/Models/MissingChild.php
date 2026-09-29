<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MissingChild extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'age',
        'photo_url',
        'description',
        'last_clothes',
        'alert_type',
        'status',
        'disappearance_lat',
        'disappearance_lng',
        'disappeared_at',
        'is_verified',
    ];

    protected $casts = [
        'disappeared_at' => 'datetime',
        'is_verified' => 'boolean',
        'disappearance_lat' => 'double',
        'disappearance_lng' => 'double',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function reports(): HasMany
    {
        return $this->hasMany(Report::class);
    }

    public function alerts(): HasMany
    {
        return $this->hasMany(Alert::class);
    }
}
