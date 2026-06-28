<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;

/**
 * Admin → Analytics (Blade). Signups + bookings trends, status breakdown,
 * and top studios — all from the cached AdminController::analytics.
 */
class AnalyticsController extends Controller
{
    public function index(AdminController $api)
    {
        $data = $api->analytics()->getData(true)['data'] ?? [];

        return view('admin.analytics.index', [
            'signups'         => $data['signups'] ?? [],
            'bookings'        => $data['bookings'] ?? [],
            'statusBreakdown' => $data['statusBreakdown'] ?? [],
            'topStudios'      => $data['topStudios'] ?? [],
        ]);
    }
}
