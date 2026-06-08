<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TeamInviteCode;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class TeamController extends Controller
{
    public function getInvite(Request $request)
    {
        $user = $request->user();
        $invite = TeamInviteCode::where('owner_id', $user->id)
            ->where('expires_at', '>', now())
            ->latest()
            ->first();

        return response()->json(['data' => $invite]);
    }

    public function invite(Request $request)
    {
        $user = $request->user();

        $code = strtoupper(Str::random(6));

        $invite = TeamInviteCode::create([
            'owner_id' => $user->id,
            'code' => $code,
            'expires_at' => now()->addDays(7),
        ]);

        return response()->json(['data' => $invite], 201);
    }

    public function members(Request $request)
    {
        $userId = $request->user()->id;

        $members = User::whereJsonContains('manager_permissions->ownerId', $userId)
            ->get();

        return response()->json(['data' => $members]);
    }

    public function updatePermissions(Request $request, $userId)
    {
        $data = $request->validate([
            'permissions' => 'required|array',
        ]);

        $member = User::find($userId);

        if (!$member) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // Authorization: the caller may only edit permissions for members of
        // their OWN team — i.e. members whose manager_permissions.ownerId is the
        // caller. This mirrors how members() scopes the team list. Without this
        // any authenticated user could grant themselves/others elevated
        // permissions on arbitrary accounts.
        $ownerId = $request->user()->id;
        $memberOwnerId = $member->manager_permissions['ownerId'] ?? null;
        // Compare as integers — the stored ownerId may be int or numeric string.
        if ($memberOwnerId === null || (int) $memberOwnerId !== (int) $ownerId) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $current = $member->manager_permissions ?? [];
        $current['permissions'] = $data['permissions'];
        // manager_permissions is a guarded field — set via forceFill.
        $member->forceFill(['manager_permissions' => $current])->save();

        return response()->json(['data' => $member->fresh()]);
    }
}
