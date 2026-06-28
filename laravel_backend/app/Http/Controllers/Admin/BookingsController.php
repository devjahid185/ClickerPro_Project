<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

/**
 * Admin → Bookings (Blade). Read-only list across all studios, reusing the
 * API's AdminController::bookings (search + status filter, capped at 100).
 */
class BookingsController extends Controller
{
    public const STATUSES = ['PENDING', 'CONFIRMED', 'IN_PROGRESS', 'SHOT_COMPLETE', 'DELIVERED', 'COMPLETED', 'SUCCESSFUL', 'CANCELLED'];

    public function index(Request $request, AdminController $api)
    {
        $payload = $api->bookings($request)->getData(true);

        return view('admin.bookings.index', [
            'bookings' => $payload['data'] ?? [],
            'total'    => $payload['total'] ?? 0,
            'search'   => (string) $request->query('search', ''),
            'status'   => (string) $request->query('status', ''),
            'statuses' => self::STATUSES,
        ]);
    }
}
