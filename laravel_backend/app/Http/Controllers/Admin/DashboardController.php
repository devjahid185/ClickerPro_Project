<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Payment;
use Illuminate\Support\Facades\Cache;

/**
 * Admin dashboard (Blade). Reuses the exact same stats payload the API's
 * AdminController produces, so the console and the API never drift — they
 * read the same cache key (`admin.stats`).
 *
 * Graphy7 Admin design additions (2026-07-12): platform revenue hero
 * (this month's payment volume + trend vs last month) and a recent-bookings
 * list — read-only platform-wide data, per Heaven's "control everything
 * from the admin panel" request.
 */
class DashboardController extends Controller
{
    public function index(AdminController $api)
    {
        // AdminController::stats() returns a JsonResponse wrapping { data: ... }.
        // Unwrap it here so the Blade view gets a plain array. This keeps the
        // stats logic in ONE place (the API controller) — DRY.
        $stats = $api->stats()->getData(true)['data'] ?? [];

        // Revenue hero — payment volume recorded across the platform this
        // month, with a % trend vs last month (design: "REVENUE · JULY,
        // trending_up 12.5% vs June"). Cached alongside the stats TTL.
        $hero = Cache::remember('admin.revenue_hero', 60, function () {
            $now = now();
            $thisMonth = (float) Payment::whereYear('created_at', $now->year)
                ->whereMonth('created_at', $now->month)
                ->sum('amount');
            $prev = $now->copy()->subMonthNoOverflow();
            $prevMonth = (float) Payment::whereYear('created_at', $prev->year)
                ->whereMonth('created_at', $prev->month)
                ->sum('amount');

            $pct = $prevMonth > 0
                ? round((($thisMonth - $prevMonth) / $prevMonth) * 100, 1)
                : null;

            return [
                'amount' => $thisMonth,
                'pct' => $pct,
                'monthLabel' => strtoupper($now->format('F')),
                'prevMonthLabel' => $prev->format('M'),
            ];
        });

        // Recent bookings (latest 5 across all studios) — design's
        // "Recent bookings" card. Read-only; row click goes to the full list.
        $recent = Event::with('client:id,name')
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get()
            ->map(fn ($e) => [
                'title' => $e->client->name ?? $e->title,
                'sub' => trim(($e->event_type ?: 'Booking') . ' · ' . optional($e->date)->format('M d'), ' ·'),
                'amount' => $e->price !== null ? (float) $e->price : null,
                'status' => $e->status,
            ]);

        return view('admin.dashboard', [
            'stats' => $stats,
            'hero' => $hero,
            'recent' => $recent,
        ]);
    }
}
