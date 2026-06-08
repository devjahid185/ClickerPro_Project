<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function summary(Request $request)
    {
        $userId = $request->user()->id;

        $eventIds = Event::where('owner_id', $userId)->pluck('id');

        $totalRevenue = Payment::whereIn('event_id', $eventIds)
            ->where('kind', '!=', 'PAYOUT')
            ->sum('amount');

        $totalBookings = Event::where('owner_id', $userId)->count();

        $completedBookings = Event::where('owner_id', $userId)
            ->where('status', 'COMPLETED')
            ->count();

        $pendingBookings = Event::where('owner_id', $userId)
            ->where('status', 'PENDING')
            ->count();

        $monthlyRevenue = Payment::whereIn('event_id', $eventIds)
            ->where('kind', '!=', 'PAYOUT')
            ->select(
                DB::raw("TO_CHAR(created_at, 'YYYY-MM') as month"),
                DB::raw('SUM(amount) as revenue')
            )
            ->groupBy('month')
            ->orderBy('month', 'desc')
            ->limit(6)
            ->get();

        return response()->json([
            'data' => [
                'total_revenue' => $totalRevenue,
                'total_bookings' => $totalBookings,
                'completed_bookings' => $completedBookings,
                'pending_bookings' => $pendingBookings,
                'monthly_revenue' => $monthlyRevenue,
            ],
        ]);
    }
}
