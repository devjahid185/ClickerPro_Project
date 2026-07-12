<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;

/**
 * Admin analytics (Blade). Platform growth metrics from the cached
 * AdminController::analytics payload — signups + bookings-per-month
 * (bookings re-enabled 2026-07-12 by Heaven's request).
 */
class AnalyticsController extends Controller
{
    public function index(AdminController $api)
    {
        $data = $api->analytics()->getData(true)['data'] ?? [];

        return view('admin.analytics.index', [
            'signups' => $data['signups'] ?? [],
            'bookings' => $data['bookings'] ?? [],
        ]);
    }
}
