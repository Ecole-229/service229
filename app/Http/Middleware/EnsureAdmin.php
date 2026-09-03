<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        abort_unless($user, 401);

        $isAdmin = method_exists($user, 'roles')
            && $user->roles()->where('name', 'admin')->exists();

        abort_unless($isAdmin, 403, 'Accès réservé à l’administration.');

        return $next($request);
    }
}
