<?php

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'admin' => \App\Http\Middleware\AdminMiddleware::class,
            'admin.web' => \App\Http\Middleware\AdminWebMiddleware::class,
            'manager' => \App\Http\Middleware\ManagerMiddleware::class,
        ]);
        // Security headers on every API response.
        $middleware->api(append: [
            \App\Http\Middleware\SecurityHeaders::class,
        ]);
        // The API surface has NO `login` named route: an unauthenticated
        // `auth:sanctum` request must yield clean 401 JSON, not a redirect
        // (returning null disables the redirect). The Blade admin console
        // DOES have `admin.login`, so guests hitting `/admin/*` are sent
        // there instead. Branch on the request path.
        $middleware->redirectGuestsTo(function (Request $request) {
            if ($request->is('admin') || $request->is('admin/*')) {
                return route('admin.login');
            }
            return null;
        });
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Force JSON for the whole API surface, then render auth failures
        // as 401 JSON.
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) =>
                $request->is('api/*') || $request->expectsJson()
        );
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            // Blade admin console: bounce guests to the login screen rather
            // than emitting 401 JSON (which the API surface still gets).
            if ($request->is('admin') || $request->is('admin/*')) {
                return redirect()->guest(route('admin.login'))
                    ->with('error', 'Please sign in to continue.');
            }
            return response()->json(['message' => 'Unauthenticated.'], 401);
        });
    })->create();
