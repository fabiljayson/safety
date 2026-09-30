<?php

namespace App\Providers;

use App\Models\User;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Schema::defaultStringLength(191);

        // The authority role is the only privileged role: it can verify alerts
        // (which mass-broadcasts to nearby phones) and reach the admin
        // dashboard. Centralised here so the check is not re-implemented as a
        // raw string comparison in every controller.
        Gate::define('verifyAlerts', fn (User $user): bool => $user->role === 'authority');

        Gate::define('accessAdminPanel', fn (User $user): bool => $user->role === 'authority');
    }
}
