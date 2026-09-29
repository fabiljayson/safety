<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Report extends Model
{
    protected $fillable = [
        'missing_child_id',
        'user_id',
        'lat',
        'lng',
        'description',
        'tracking_path',
        'photo_url',
        'sighted_at',
    ];

    protected $casts = [
        'sighted_at' => 'datetime',
        'lat' => 'double',
        'lng' => 'double',
        'tracking_path' => 'array',
    ];

    public function missingChild(): BelongsTo
    {
        return $this->belongsTo(MissingChild::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
