<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'phone', 'role', 'last_lat', 'last_lng', 'fcm_token'])]
#[Hidden(['password', 'remember_token', 'fcm_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Columns that may be loaded when a user is nested inside another resource
     * (the author of a sighting, the reporter of an alert).
     *
     * The FCM push token is a credential for delivering pushes to the device,
     * and the email, phone number and last known GPS position are personal
     * data that the public feed has no reason to expose. The reporter is
     * still identified by name; the owning user keeps full access to their
     * own record through /me.
     *
     * @return list<string>
     */
    public static function publicColumns(): array
    {
        return ['id', 'name', 'role'];
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
