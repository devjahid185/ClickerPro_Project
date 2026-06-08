<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AccountController extends Controller
{
    public function requestDelete(Request $request)
    {
        $user = $request->user();
        $user->deleted_at = now()->addDays(7);
        $user->save();

        return response()->json(['message' => 'Account scheduled for deletion in 7 days']);
    }

    public function cancelDelete(Request $request)
    {
        $user = $request->user();
        $user->deleted_at = null;
        $user->save();

        return response()->json(['message' => 'Account deletion cancelled']);
    }
}
