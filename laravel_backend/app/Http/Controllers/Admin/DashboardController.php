<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;

/**
 * Admin dashboard (Blade). Reuses the exact same stats payload the API's
 * AdminController produces, so the console and the API never drift — they
 * read the same cache key (`admin.stats`).
 */
class DashboardController extends Controller
{
    public function index(AdminController $api)
    {
        // AdminController::stats() returns a JsonResponse wrapping { data: ... }.
        // Unwrap it here so the Blade view gets a plain array. This keeps the
        // stats logic in ONE place (the API controller) — DRY.
        $stats = $api->stats()->getData(true)['data'] ?? [];

        return view('admin.dashboard', ['stats' => $stats]);
    }
}
