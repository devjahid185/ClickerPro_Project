<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

/**
 * Admin → Finance (Blade). Revenue summary + method breakdown + recent
 * payments + a bookings-per-month series, all sourced from the API's
 * AdminController (payments + analytics).
 */
class FinanceController extends Controller
{
    public function index(Request $request, AdminController $api)
    {
        $pay = $api->payments($request)->getData(true);
        $analytics = $api->analytics()->getData(true)['data'] ?? [];

        $payments = $pay['data'] ?? [];

        // Method breakdown from the loaded payment rows.
        $byMethod = [];
        foreach (['CASH', 'BKASH', 'NAGAD', 'BANK', 'CARD', 'OTHER'] as $m) {
            $byMethod[$m] = 0.0;
        }
        foreach ($payments as $p) {
            $m = strtoupper($p['method'] ?? 'OTHER');
            if (! array_key_exists($m, $byMethod)) {
                $m = 'OTHER';
            }
            $byMethod[$m] += (float) ($p['amount'] ?? 0);
        }

        return view('admin.finance.index', [
            'totalAmount'  => $pay['totalAmount'] ?? 0,
            'total'        => $pay['total'] ?? 0,
            'payments'     => array_slice($payments, 0, 20),
            'byMethod'     => $byMethod,
            'bookingsSeries' => $analytics['bookings'] ?? [],
        ]);
    }
}
