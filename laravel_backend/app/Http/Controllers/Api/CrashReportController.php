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
}
