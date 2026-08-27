<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use Illuminate\Http\Request;

class DeviceTokenController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'token' => 'required|string',
            'platform' => 'nullable|string|in:android,ios,web',
        ]);

        // A physical device has one FCM token. When a tester/user logs out
        // and signs into another account on the same phone, move that token
        // to the current user instead of leaving duplicate rows behind.
        DeviceToken::where('token', $data['token'])
            ->where('user_id', '!=', $request->user()->id)
            ->delete();

        $deviceToken = DeviceToken::updateOrCreate(
            ['user_id' => $request->user()->id, 'token' => $data['token']],
            ['platform' => $data['platform'] ?? 'android']
        );

        return response()->json(['data' => $deviceToken]);
    }

    /** Remove the caller's device token (called on logout). */
    public function unregister(Request $request, $token)
    {
        DeviceToken::where('user_id', $request->user()->id)
            ->where('token', $token)
            ->delete();

        return response()->json(['message' => 'ok']);
    }
}
