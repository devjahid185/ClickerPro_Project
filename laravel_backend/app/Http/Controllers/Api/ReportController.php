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

    /**
     * Yearly profit & loss: revenue (non-PAYOUT payments) vs expenses +
     * freelancer payouts for the given year.
     */
    public function yearlySummary(Request $request)
    {
        $userId = $request->user()->id;
        $year = (int) $request->get('year', now()->year);

        $eventIds = Event::where('owner_id', $userId)->pluck('id');

        $totalRevenue = (float) Payment::whereIn('event_id', $eventIds)
            ->where('kind', '!=', 'PAYOUT')
            ->whereYear('created_at', $year)
            ->sum('amount');

        $totalPayouts = (float) Payment::whereIn('event_id', $eventIds)
            ->where('kind', 'PAYOUT')
            ->whereYear('created_at', $year)
            ->sum('amount');

        $totalExpenses = (float) \App\Models\Expense::where('owner_id', $userId)
            ->whereYear('created_at', $year)
            ->sum('amount');

        return response()->json([
            'data' => [
                'year' => (string) $year,
                'summary' => [
                    'totalRevenue' => $totalRevenue,
                    'totalExpenses' => $totalExpenses,
                    'totalFreelancerPayouts' => $totalPayouts,
                    'netProfit' => $totalRevenue - ($totalExpenses + $totalPayouts),
                ],
            ],
        ]);
    }

    /**
     * Per-team-member leaderboard: assignment count, payout earnings and
     * pending re-edits. score = events*10 - reedits*5 (the formula the
     * mobile app renders).
     */
    public function teamPerformance(Request $request)
    {
        $userId = $request->user()->id;
        $year = (int) $request->get('year', 0);

        $eventIds = Event::where('owner_id', $userId)->pluck('id');

        $assignments = \App\Models\Assignment::whereIn('event_id', $eventIds)
            ->when($year > 0, fn ($q) => $q->whereYear('created_at', $year))
            ->with('user:id,name,role')
            ->get();

        $pendingReEdits = \App\Models\ReEditRequest::whereIn('event_id', $eventIds)
            ->where('status', 'PENDING')
            ->get()
            ->groupBy('requested_by');

        $rows = $assignments
            ->groupBy('user_id')
            ->map(function ($group, $memberId) use ($pendingReEdits) {
                $user = $group->first()->user;
                $events = $group->count();
                $reedits = ($pendingReEdits->get($memberId) ?? collect())->count();
                return [
                    'userId' => (string) $memberId,
                    'name' => $user->name ?? 'Member',
                    'role' => $user->role ?? 'FREELANCER',
                    'totalEvents' => $events,
                    'totalEarnings' => (float) $group->sum('payout'),
                    'pendingReEdits' => $reedits,
                    'performanceScore' => $events * 10 - $reedits * 5,
                ];
            })
            ->sortByDesc('performanceScore')
            ->values();

        return response()->json([
            'data' => ['teamPerformance' => $rows],
        ]);
    }
}
