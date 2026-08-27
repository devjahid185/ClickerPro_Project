<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

/**
 * Admin â†’ Finance (Blade). Revenue summary + method breakdown + recent
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

        return view('admin.finance.index', [
            'totalAmount'  => $pay['totalAmount'] ?? 0,
            'total'        => $pay['total'] ?? 0,
            'payments'     => array_slice($payments, 0, 20),
            'byMethod'     => $this->methodBreakdown($payments),
            'bookingsSeries' => $analytics['bookings'] ?? [],
        ]);
    }

    public function exportCsv(Request $request, AdminController $api)
    {
        $payments = $api->payments($request)->getData(true)['data'] ?? [];
        $headers = ['amount', 'method', 'transaction_id', 'date', 'studio', 'booking', 'client', 'status'];
        $csv = implode(',', $headers) . "\n";

        foreach ($payments as $payment) {
            $row = [
                $payment['amount'] ?? 0,
                $payment['method'] ?? '',
                $payment['transactionId'] ?? '',
                (string) ($payment['paidAt'] ?? $payment['date'] ?? ''),
                $payment['event']['owner']['businessName'] ?? $payment['event']['owner']['fullName'] ?? '',
                $payment['event']['title'] ?? '',
                $payment['event']['client']['name'] ?? '',
                $payment['status'] ?? $payment['kind'] ?? '',
            ];

            $csv .= implode(',', array_map(fn ($value) => '"' . str_replace('"', '""', (string) $value) . '"', $row)) . "\n";
        }

        return response($csv, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="finance_payments_export.csv"',
        ]);
    }

    private function methodBreakdown(array $payments): array
    {
        $byMethod = [];
        foreach (['CASH', 'BKASH', 'NAGAD', 'BANK', 'CARD', 'OTHER'] as $method) {
            $byMethod[$method] = 0.0;
        }

        foreach ($payments as $payment) {
            $method = strtoupper($payment['method'] ?? 'OTHER');
            if (! array_key_exists($method, $byMethod)) {
                $method = 'OTHER';
            }
            $byMethod[$method] += (float) ($payment['amount'] ?? 0);
        }

        return $byMethod;
    }
}
