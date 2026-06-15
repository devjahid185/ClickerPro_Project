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
            'manager' => \App\Http\Middleware\ManagerMiddleware::class,
        ]);
        // Security headers on every API response.
        $middleware->api(append: [
            \App\Http\Middleware\SecurityHeaders::class,
        ]);
        // This is an API-only backend with NO `login` named route. When an
        // unauthenticated request reaches `auth:sanctum`, Laravel's default
        // guest handler tries to redirect to route('login') and crashes
        // with "Route [login] not defined" → a 500. Returning null here
        // disables the redirect so the AuthenticationException renderer
        // below produces a clean 401 JSON for EVERY unauthenticated request
        // (even when the client didn't send `Accept: application/json`).
        $middleware->redirectGuestsTo(fn () => null);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Force JSON for the whole API surface, then render auth failures
        // as 401 JSON.
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) =>
                $request->is('api/*') || $request->expectsJson()
        );
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        });
    })->create();
