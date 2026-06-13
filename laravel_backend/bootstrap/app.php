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
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // This is an API-only backend with no `login` named route. An
        // unauthenticated request (missing / expired Sanctum token) must
        // return a clean 401 JSON — NOT crash with "Route [login] not
        // defined" (which surfaced as a 500 in the admin panel).
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        });
    })->create();
