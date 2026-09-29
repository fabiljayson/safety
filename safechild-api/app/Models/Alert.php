<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Alert extends Model
{
    protected $fillable = [
        'missing_child_id',
        'title',
        'message',
        'users_notified_count',
        'radius_km',
    ];

    protected $casts = [
        'users_notified_count' => 'integer',
        'radius_km' => 'double',
    ];

    public function missingChild(): BelongsTo
    {
        return $this->belongsTo(MissingChild::class);
    }
}
