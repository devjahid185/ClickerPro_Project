<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

/**
 * Admin businesses (Blade). A studio-oriented view of OWNER accounts,
 * reusing the API users endpoint with role=OWNER.
 */
class StudiosController extends Controller
{
    public function index(Request $request, AdminController $api)
    {
        $request->merge(['role' => 'OWNER']);
        $payload = $api->users($request)->getData(true);

        return view('admin.studios.index', [
            'studios' => $payload['data'] ?? [],
            'total'   => $payload['total'] ?? 0,
            'search'  => (string) $request->query('search', ''),
        ]);
    }
}
