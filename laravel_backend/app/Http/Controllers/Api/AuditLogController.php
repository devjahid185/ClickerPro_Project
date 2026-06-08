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

        $logs = $query->limit(100)->get()->map(fn ($l) => [
            'id' => (string) $l->id,
            'actorName' => 'System',
            'action' => $l->action,
            'entityType' => $l->entity,
            'entityId' => (string) $l->entity_id,
            'entityLabel' => null,
            'createdAt' => $l->created_at?->toIso8601String(),
        ]);

        return response()->json(['data' => $logs, 'total' => $logs->count()]);
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
