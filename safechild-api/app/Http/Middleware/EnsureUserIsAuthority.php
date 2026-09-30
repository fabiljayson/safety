<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Restricts the admin panel to the "authority" role.
 *
 * The role used to be checked once, inside the login action. That left the
 * dashboard reachable to any authenticated session (for example one created
 * before the account's role was changed), so the check is enforced on every
 * admin request instead.
 */
class EnsureUserIsAuthority
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user || ! $user->can('accessAdminPanel')) {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'Non autorisé.'], 403);
            }

            return redirect()->route('admin.login')
                ->withErrors(['email' => 'Accès refusé. Seules les autorités peuvent accéder à cette interface.']);
        }

        return $next($request);
    }
}
