<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/**
 * Admin Ã¢â€ â€™ Users (Blade). Ports the Next.js users screen onto the Laravel
 * console. List/filter/export reuse the API's AdminController so behaviour
 * stays identical; mutations (role/plan/suspend/create) post back here and
 * apply through the same guarded model paths.
 */
class UsersController extends Controller
{
    private const ROLES = ['OWNER', 'FREELANCER', 'BOTH', 'MANAGER', 'ADMIN'];

    public function index(Request $request, AdminController $api)
    {
        // Reuse the API list endpoint (search + role filter, capped at 100)
        // so the console and the mobile/API admin never diverge.
        $payload = $api->users($request)->getData(true);

        return view('admin.users.index', [
            'users'    => $payload['data'] ?? [],
            'total'    => $payload['total'] ?? 0,
            'search'   => (string) $request->query('search', ''),
            'role'     => (string) $request->query('role', ''),
            'activity' => (string) $request->query('activity', ''),
            'roles'    => self::ROLES,
        ]);
    }

    public function show($id, AdminController $api)
    {
        // Reuse the API detail endpoint Ã¢â€ â€™ { user, stats, bookings }.
        $resp = $api->userDetail($id);
        if ($resp->getStatusCode() === 404) {
            abort(404);
        }
        $payload = $resp->getData(true)['data'] ?? [];

        return view('admin.users.show', [
            'user'     => $payload['user'] ?? [],
            'stats'    => $payload['stats'] ?? [],
            'bookings' => $payload['bookings'] ?? [],
            'roles'    => self::ROLES,
        ]);
    }

    public function setRole(Request $request, $id)
    {
        $data = $request->validate([
            'role' => ['required', 'string', 'in:' . implode(',', self::ROLES)],
        ]);
        $user = User::findOrFail($id);
        // role is a guarded field Ã¢â‚¬â€ set it explicitly via forceFill.
        $user->forceFill(['role' => $data['role']])->save();

        return back()->with('status', "Role updated to {$data['role']} for {$user->email}.");
    }

    public function setPlan(Request $request, $id)
    {
        $data = $request->validate(['plan' => ['required', 'string', 'in:FREE,PRO']]);
        $user = User::findOrFail($id);
        $user->forceFill(['plan' => $data['plan']])->save();

        return back()->with('status', "Plan set to {$data['plan']} for {$user->email}.");
    }

    public function suspend(Request $request, $id)
    {
        $data = $request->validate(['suspended' => ['required', 'boolean']]);
        $user = User::findOrFail($id);
        // suspended=true Ã¢â€ â€™ deactivate; false Ã¢â€ â€™ reactivate.
        $user->forceFill(['is_active' => ! $data['suspended']])->save();

        $verb = $data['suspended'] ? 'suspended' : 'reactivated';
        return back()->with('status', "{$user->email} {$verb}.");
    }

    public function destroy(Request $request, $id)
    {
        $user = User::findOrFail($id);

        if ((int) $request->user()->id === (int) $user->id) {
            return back()->withErrors(['user' => 'You cannot delete your own admin account.']);
        }

        if (strtoupper((string) $user->role) === 'ADMIN') {
            return back()->withErrors(['user' => 'Admin accounts cannot be deleted from this screen.']);
        }

        $recentlyActive = $user->last_active_at !== null
            && $user->last_active_at->diffInDays(now()) < 30;
        if ($user->is_active && $recentlyActive) {
            return back()->withErrors(['user' => 'Recently active users must be suspended before deletion.']);
        }

        $email = $user->email;
        $user->tokens()->delete();
        $user->forceDelete();

        return redirect()->route('admin.users')
            ->with('status', "User {$email} permanently deleted.");
    }
    public function store(Request $request)
    {
        // The Next.js panel POSTed to a /api/admin/users endpoint that never
        // existed (404). Implement it here so create actually works.
        $data = $request->validate([
            'name'     => ['required', 'string', 'max:255'],
            'email'    => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role'     => ['required', 'string', 'in:' . implode(',', self::ROLES)],
        ]);

        $user = new User();
        $user->forceFill([
            'name'      => $data['name'],
            'email'     => $data['email'],
            'password'  => Hash::make($data['password']),
            'role'      => $data['role'],
            'plan'      => 'FREE',
            'is_active' => true,
        ])->save();

        return redirect()->route('admin.users')
            ->with('status', "User {$user->email} created.");
    }

    public function exportCsv(Request $request, AdminController $api)
    {
        // Delegate to the API CSV builder (type=users).
        $request->merge(['type' => 'users']);
        return $api->exportCsv($request);
    }
}
