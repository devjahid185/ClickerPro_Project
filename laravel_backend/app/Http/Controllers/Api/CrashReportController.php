<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CrashReport;
use Illuminate\Http\Request;

class CrashReportController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'error' => 'required|string',
            'stackTrace' => 'nullable|string',
            'userRole' => 'nullable|string|max:50',
            'breadcrumbs' => 'nullable|array',
            'platform' => 'nullable|string|max:50',
            'appVersion' => 'nullable|string|max:50',
        ]);

        CrashReport::create([
            'user_id' => $request->user()?->id,
            'user_role' => $data['userRole'] ?? null,
            'error' => $data['error'],
            'stack_trace' => $data['stackTrace'] ?? null,
            'breadcrumbs' => $data['breadcrumbs'] ?? null,
            'platform' => $data['platform'] ?? null,
            'app_version' => $data['appVersion'] ?? null,
        ]);

        return response()->json(['message' => 'ok'], 201);
    }

    // ── Admin-only (auth:sanctum + admin middleware, prefix admin/) ──

    /**
     * Newest-first crash/bug list for the admin console, unresolved first so
     * open issues stay on top. Capped at 200 — the console shows recent
     * activity, not the full history.
     */
    public function adminIndex(Request $request)
    {
        $reports = CrashReport::query()
            ->with('user:id,name,email')
            ->orderByRaw('resolved_at IS NULL DESC')
            ->orderByDesc('created_at')
            ->limit(200)
            ->get()
            ->map(fn (CrashReport $r) => $this->row($r));

        return response()->json([
            'data' => $reports,
            'unresolved' => $reports->where('resolved', false)->count(),
        ]);
    }

    public function adminResolve(Request $request, $id)
    {
        $report = CrashReport::find($id);
        if (!$report) {
            return response()->json(['message' => 'Not found'], 404);
        }
        // Toggle: resolving stamps now; un-resolving clears it.
        $resolve = $request->boolean('resolved', true);
        $report->resolved_at = $resolve ? now() : null;
        $report->save();

        return response()->json(['data' => $this->row($report)]);
    }

    public function adminDestroy($id)
    {
        $report = CrashReport::find($id);
        if (!$report) {
            return response()->json(['message' => 'Not found'], 404);
        }
        $report->delete();

        return response()->json(['message' => 'ok']);
    }

    // Shape a CrashReport into the camelCase form the admin UI expects.
    private function row(CrashReport $r): array
    {
        return [
            'id' => (string) $r->id,
            'error' => $r->error,
            'stackTrace' => $r->stack_trace,
            'breadcrumbs' => $r->breadcrumbs ?? [],
            'platform' => $r->platform,
            'appVersion' => $r->app_version,
            'userRole' => $r->user_role,
            'userName' => $r->user?->name,
            'userEmail' => $r->user?->email,
            'resolved' => $r->resolved_at !== null,
            'resolvedAt' => $r->resolved_at?->toIso8601String(),
            'createdAt' => $r->created_at?->toIso8601String(),
        ];
    }
}
