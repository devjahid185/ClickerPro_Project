<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

/**
 * Admin → Payments (Blade). Read-only list across all studios, reusing the
 * API's AdminController::payments (capped at 200, with grand total).
 */
class PaymentsController extends Controller
{
    public function index(Request $request, AdminController $api)
    {
        $payload = $api->payments($request)->getData(true);

        return view('admin.payments.index', [
            'payments'    => $payload['data'] ?? [],
            'total'       => $payload['total'] ?? 0,
            'totalAmount' => $payload['totalAmount'] ?? 0,
        ]);
    }
}
