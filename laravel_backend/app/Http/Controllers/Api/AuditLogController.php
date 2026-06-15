<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\Request;

class AuditLogController extends Controller
{
    public function index(Request $request)
    {
        $query = AuditLog::orderBy('created_at', 'desc');

        if ($request->entity) $query->where('entity', $request->entity);
        if ($request->action) $query->where('action', $request->action);

        $total = (clone $query)->count();
        $limit = min(max((int) $request->get('limit', 100), 1), 200);
        $offset = max((int) $request->get('offset', 0), 0);

        // Resolve actor names in one pass instead of N queries.
        $rows = $query->offset($offset)->limit($limit)->get();
        $actorNames = \App\Models\User::whereIn('id', $rows->pluck('actor_id')->filter()->unique())
            ->pluck('name', 'id');

        $logs = $rows->map(fn ($l) => [
            'id' => (string) $l->id,
            'actorName' => $actorNames[$l->actor_id] ?? 'System',
            'action' => $l->action,
            'entityType' => $l->entity,
            'entityId' => (string) $l->entity_id,
            'entityLabel' => null,
            'createdAt' => $l->created_at?->toIso8601String(),
        ]);

        return response()->json(['data' => $logs, 'total' => $total]);
    }

    // User-facing: the signed-in user's own activity trail.
    public function mine(Request $request)
    {
        $logs = AuditLog::where('actor_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->limit(100)->get()->map(fn ($l) => [
                'id' => (string) $l->id,
                'action' => $l->action,
                'entityType' => $l->entity,
                'entityId' => (string) $l->entity_id,
                'ip' => $l->ip,
                'createdAt' => $l->created_at?->toIso8601String(),
            ]);

        return response()->json(['data' => $logs]);
    }
}
