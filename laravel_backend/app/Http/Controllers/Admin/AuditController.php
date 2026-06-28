<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AuditLogController;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

/**
 * Admin → Audit Log (Blade). Read-only audit trail, reusing AuditLogController
 * (entity/action filters, capped at 200).
 */
class AuditController extends Controller
{
    public function index(Request $request, AuditLogController $api)
    {
        $payload = $api->index($request)->getData(true);

        return view('admin.audit.index', [
            'logs'   => $payload['data'] ?? [],
            'total'  => $payload['total'] ?? 0,
            'entity' => (string) $request->query('entity', ''),
            'action' => (string) $request->query('action', ''),
        ]);
    }
}
