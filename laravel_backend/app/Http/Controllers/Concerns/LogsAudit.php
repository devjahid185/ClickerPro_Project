<?php

namespace App\Http\Controllers\Concerns;

use App\Models\AuditLog;
use Illuminate\Http\Request;

/**
 * Server-side audit trail helper. Controllers call [audit()] after a
 * create / update / delete so the change lands in `audit_logs` — the same
 * table the Audit Log screen reads via GET /api/audit-logs.
 *
 * Writing server-side (rather than trusting a client POST) keeps the trail
 * tamper-proof: the actor is the authenticated user, never a client-supplied
 * field. Fail-soft — an audit write must never break the underlying request,
 * so any error is swallowed.
 */
trait LogsAudit
{
    /**
     * Record one audit entry.
     *
     * @param  string  $action  CREATE | UPDATE | DELETE | PERMISSION
     * @param  string  $entity  e.g. 'booking', 'payment', 'client'
     * @param  array<string,mixed>|null  $before  prior state (updates/deletes)
     * @param  array<string,mixed>|null  $after   new state (creates/updates)
     */
    protected function audit(
        Request $request,
        string $action,
        string $entity,
        string|int|null $entityId,
        ?array $before = null,
        ?array $after = null,
    ): void {
        try {
            AuditLog::create([
                'actor_id' => $request->user()?->id,
                'action' => strtoupper($action),
                'entity' => $entity,
                'entity_id' => $entityId === null ? null : (string) $entityId,
                'before' => $before,
                'after' => $after,
                'ip' => $request->ip(),
            ]);
        } catch (\Throwable $e) {
            // Never let auditing break the request it is recording.
            report($e);
        }
    }
}
