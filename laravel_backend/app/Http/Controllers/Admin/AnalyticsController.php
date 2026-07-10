<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;

/**
 * Admin analytics (Blade). Shows privacy-safe platform growth metrics from
 * the cached AdminController::analytics payload.
 */
class AnalyticsController extends Controller
{
    public function index(AdminController $api)
    {
        $data = $api->analytics()->getData(true)['data'] ?? [];

        return view('admin.analytics.index', [
            'signups' => $data['signups'] ?? [],
        ]);
    }
}
