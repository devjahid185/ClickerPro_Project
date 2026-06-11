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

    /**
     * GDPR-style data export: dumps the user's own rows (profile, events,
     * clients, payments) to a JSON file on the public disk and returns a
     * download link.
     */
    public function export(Request $request)
    {
        $user = $request->user();

        $eventIds = \App\Models\Event::where('owner_id', $user->id)->pluck('id');

        $payload = [
            'exported_at' => now()->toIso8601String(),
            'profile' => $user->only([
                'id', 'name', 'email', 'phone', 'role', 'plan',
                'business_name', 'bio', 'created_at',
            ]),
            'events' => \App\Models\Event::where('owner_id', $user->id)->get(),
            'clients' => \App\Models\Client::where('owner_id', $user->id)->get(),
            'payments' => \App\Models\Payment::whereIn('event_id', $eventIds)->get(),
        ];

        $filename = 'exports/export_' . $user->id . '_' . now()->format('Ymd_His') . '.json';
        \Illuminate\Support\Facades\Storage::disk('public')->put(
            $filename,
            json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
        );

        $url = \Illuminate\Support\Facades\Storage::url($filename);

        return response()->json([
            'data' => [
                'downloadUrl' => url($url),
            ],
        ]);
    }
}
