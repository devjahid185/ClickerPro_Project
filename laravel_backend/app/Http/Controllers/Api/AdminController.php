<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Payment;
use App\Models\User;
use App\Models\Client;
use App\Models\Broadcast;
use App\Models\SupportTicket;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    // Admin dashboard aggregates are recomputed at most once per minute.
    // 60s is fresh enough for an operator dashboard and removes the repeated
    // ~8–10 aggregate queries on every refresh. Same response shape/values.
    private const DASHBOARD_TTL = 60;

    public function stats()
    {
        $data = Cache::remember('admin.stats', self::DASHBOARD_TTL, function () {
            // Revenue is stored in major units (Taka); admin UI divides by 100,
            // so report it in minor units (paisa) to match its expectation.
            $revenue = (float) Payment::where('kind', '!=', 'PAYOUT')->sum('amount');

            return [
                'totalUsers'        => User::count(),
                'owners'            => User::whereIn('role', ['OWNER', 'BOTH'])->count(),
                'freelancers'       => User::whereIn('role', ['FREELANCER', 'BOTH'])->count(),
                'admins'            => User::where('role', 'ADMIN')->count(),
                'totalBookings'     => Event::count(),
                'totalClients'      => Client::count(),
                'activeBroadcasts'  => Broadcast::where('is_active', true)->count(),
                'openTickets'       => SupportTicket::whereIn('status', ['OPEN', 'IN_PROGRESS'])->count(),
                'totalRevenueMinor' => (int) round($revenue * 100),
            ];
        });

        return response()->json(['data' => $data]);
    }

    public function analytics()
    {
        $data = Cache::remember('admin.analytics', self::DASHBOARD_TTL, function () {
            $signups = User::select(
                    DB::raw("TO_CHAR(created_at, 'YYYY-MM') as month"),
                    DB::raw('COUNT(*) as count')
                )
                ->groupBy('month')->orderBy('month')->limit(12)->get();

            $bookings = Event::select(
                    DB::raw("TO_CHAR(created_at, 'YYYY-MM') as month"),
                    DB::raw('COUNT(*) as count')
                )
                ->groupBy('month')->orderBy('month')->limit(12)->get();

            $statusBreakdown = Event::select('status', DB::raw('COUNT(*) as count'))
                ->groupBy('status')->get();

            $topRows = Event::select('owner_id', DB::raw('COUNT(*) as bookings'))
                ->groupBy('owner_id')->orderByDesc('bookings')->limit(5)->get();

            // Batch-load the owners in a single query (was N+1: one find() per
            // row) and resolve names from the in-memory map — identical output.
            $owners = User::whereIn('id', $topRows->pluck('owner_id'))
                ->get(['id', 'name', 'business_name'])
                ->keyBy('id');

            $topStudios = $topRows->map(function ($row) use ($owners) {
                $owner = $owners->get($row->owner_id);
                return [
                    'ownerId'  => (string) $row->owner_id,
                    'name'     => $owner?->business_name ?: ($owner?->name ?? 'Unknown'),
                    'bookings' => (int) $row->bookings,
                ];
            });

            return [
                'signups'         => $signups,
                'bookings'        => $bookings,
                'statusBreakdown' => $statusBreakdown,
                'topStudios'      => $topStudios,
            ];
        });

        return response()->json(['data' => $data]);
    }

    public function users(Request $request)
    {
        $query = User::withCount('events')->orderBy('created_at', 'desc');

        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->has('role') && $request->role) {
            $query->where('role', $request->role);
        }

        $users = $query->limit(100)->get()->map(fn ($u) => $this->userRow($u));

        return response()->json(['data' => $users, 'total' => $users->count()]);
    }

    // Shape a User into the camelCase form the admin UI expects.
    private function userRow($u): array
    {
        return [
            'id' => (string) $u->id,
            'email' => $u->email,
            'fullName' => $u->name,
            'phone' => $u->phone,
            'role' => $u->role,
            'plan' => $u->plan,
            'planExpiresAt' => $u->plan_expires_at ?? null,
            'businessName' => $u->business_name,
            'totalEvents' => $u->events_count ?? 0,
            'totalRevenueMinor' => 0,
            'deletedAt' => $u->is_active ? null : ($u->updated_at?->toIso8601String()),
            'createdAt' => $u->created_at?->toIso8601String(),
        ];
    }

    public function userDetail($id)
    {
        $user = User::withCount(['events', 'clients'])->find($id);

        if (!$user) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // The admin UI renders {user, stats, bookings} — returning the raw
        // row made every field read crash client-side (data.user.fullName).
        $eventIds = Event::where('owner_id', $user->id)->pluck('id');
        $paymentsCount = Payment::whereIn('event_id', $eventIds)->count();
        $paymentsTotal = (float) Payment::whereIn('event_id', $eventIds)->sum('amount');

        $bookings = Event::where('owner_id', $user->id)
            ->with('client:id,name')
            ->orderBy('date', 'desc')
            ->limit(15)
            ->get()
            ->map(fn ($e) => [
                'id' => (string) $e->id,
                'title' => $e->title,
                'type' => $e->event_type,
                'date' => $e->date,
                'status' => $e->status,
                'venue' => $e->venue,
                'client' => $e->client ? ['name' => $e->client->name] : null,
            ]);

        return response()->json(['data' => [
            'user' => array_merge($this->userRow($user), [
                'whatsapp' => $user->whatsapp ?? null,
                'businessAddress' => $user->business_address ?? null,
            ]),
            'stats' => [
                'bookings' => $user->events_count ?? 0,
                'clients' => $user->clients_count ?? 0,
                'paymentsCount' => $paymentsCount,
                'paymentsTotal' => $paymentsTotal,
            ],
            'bookings' => $bookings,
        ]]);
    }

    public function updateUser(Request $request, $id)
    {
        $user = User::find($id);

        if (!$user) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'role' => 'nullable|string|in:OWNER,FREELANCER,BOTH,MANAGER,ADMIN',
            'plan' => 'nullable|string|in:FREE,PRO',
            'is_active' => 'nullable|boolean',
            'name' => 'nullable|string|max:255',
            'business_name' => 'nullable|string|max:255',
        ]);

        // Admin-only endpoint (admin middleware). Privilege fields are guarded,
        // so apply via forceFill from the validated data.
        $user->forceFill(array_filter($data, fn($v) => $v !== null))->save();

        return response()->json(['data' => $user->fresh()]);
    }

    // ── Per-field user actions used by the admin Users page ──
    public function setRole(Request $request, $id)
    {
        $data = $request->validate(['role' => 'required|string|in:OWNER,FREELANCER,BOTH,MANAGER,ADMIN']);
        $user = User::findOrFail($id);
        $user->forceFill(['role' => $data['role']])->save();
        return response()->json(['data' => $user->fresh()]);
    }

    public function setPlan(Request $request, $id)
    {
        $data = $request->validate(['plan' => 'required|string|in:FREE,PRO']);
        $user = User::findOrFail($id);
        $user->forceFill(['plan' => $data['plan']])->save();
        return response()->json(['data' => $user->fresh()]);
    }

    public function setSuspend(Request $request, $id)
    {
        $data = $request->validate(['suspended' => 'required|boolean']);
        $user = User::findOrFail($id);
        // suspended=true → soft-deactivate; false → reactivate
        $user->forceFill(['is_active' => !$data['suspended']])->save();
        return response()->json(['data' => $user->fresh()]);
    }

    // ── Admin bookings list (all studios) ──
    public function bookings(Request $request)
    {
        $query = Event::with(['client:id,name', 'owner:id,name,business_name'])
            ->orderBy('date', 'desc');

        if ($request->status) $query->where('status', $request->status);
        if ($request->search) {
            $s = $request->search;
            $query->where(fn ($q) => $q->where('title', 'like', "%{$s}%")->orWhere('venue', 'like', "%{$s}%"));
        }

        $total = $query->count();
        $items = $query->limit(100)->get()->map(function ($e) {
            return [
                'id' => (string) $e->id,
                'title' => $e->title,
                'type' => $e->event_type,
                'date' => $e->date,
                'status' => $e->status,
                'venue' => $e->venue,
                'client' => $e->client ? ['name' => $e->client->name] : null,
                'owner' => $e->owner ? [
                    'id' => (string) $e->owner->id,
                    'fullName' => $e->owner->name,
                    'businessName' => $e->owner->business_name,
                ] : null,
            ];
        });

        return response()->json(['data' => $items, 'total' => $total]);
    }

    // ── Admin payments list (all studios) ──
    public function payments(Request $request)
    {
        $query = Payment::with(['event:id,title,owner_id,client_id', 'event.owner:id,name,business_name,email', 'event.client:id,name'])
            ->orderBy('created_at', 'desc');

        $totalAmount = (float) (clone $query)->sum('amount');
        $total = (clone $query)->count();

        $items = $query->limit(200)->get()->map(function ($p) {
            return [
                'id' => (string) $p->id,
                'amount' => (float) $p->amount,
                'kind' => $p->kind,
                'method' => $p->method,
                'transactionId' => $p->transaction_id ?? null,
                'date' => $p->paid_at ?? $p->created_at,
                'note' => $p->note,
                'event' => $p->event ? [
                    'title' => $p->event->title,
                    'owner' => $p->event->owner ? ['fullName' => $p->event->owner->name, 'businessName' => $p->event->owner->business_name] : null,
                    'client' => $p->event->client ? ['name' => $p->event->client->name] : null,
                ] : null,
                // Aliases the admin Finance page renders directly.
                'status' => $p->kind === 'DUE' ? 'PENDING' : 'COMPLETED',
                'paidAt' => $p->paid_at ?? $p->created_at,
                'currency' => 'BDT',
                'user' => $p->event?->owner ? [
                    'id' => (string) $p->event->owner->id,
                    'fullName' => $p->event->owner->name,
                    'email' => $p->event->owner->email ?? '',
                ] : null,
                'booking' => $p->event ? [
                    'id' => (string) $p->event->id,
                    'title' => $p->event->title,
                ] : null,
            ];
        });

        return response()->json(['data' => $items, 'total' => $total, 'totalAmount' => $totalAmount]);
    }

    public function exportCsv(Request $request, $file = null)
    {
        // Accept either ?type=bookings or /export/bookings.csv
        $type = $request->get('type');
        if (!$type && $file) {
            $type = pathinfo($file, PATHINFO_FILENAME); // "bookings.csv" → "bookings"
        }
        $type = $type ?: 'users';

        if ($type === 'users') {
            $rows = User::select('id', 'name', 'email', 'phone', 'role', 'plan', 'business_name', 'is_active', 'created_at')->get();
            $headers = ['id', 'name', 'email', 'phone', 'role', 'plan', 'business_name', 'is_active', 'created_at'];
        } else {
            $rows = Event::with('client', 'owner')
                ->select('id', 'title', 'date', 'status', 'price', 'advance_paid', 'due_amount', 'owner_id', 'client_id', 'created_at')
                ->get();
            $headers = ['id', 'title', 'date', 'status', 'price', 'advance_paid', 'due_amount', 'owner_id', 'client_id', 'created_at'];
        }

        $csv = implode(',', $headers) . "\n";

        foreach ($rows as $row) {
            $values = array_map(function ($h) use ($row) {
                $val = $row->$h ?? '';
                return '"' . str_replace('"', '""', $val) . '"';
            }, $headers);
            $csv .= implode(',', $values) . "\n";
        }

        return response($csv, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="' . $type . '_export.csv"',
        ]);
    }
}
