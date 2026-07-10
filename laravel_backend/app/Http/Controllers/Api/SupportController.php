<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\SupportTicket;
use Illuminate\Http\Request;

class SupportController extends Controller
{
    /**
     * Public support contact channels, editable from the admin Settings page
     * (keys `support.email` / `support.whatsapp`). The WhatsApp number is
     * returned so the app can open a wa.me chat, but the app never shows the
     * raw number to the user — only the app name / a "Chat on WhatsApp" CTA.
     */
    public function config()
    {
        return response()->json([
            'data' => [
                'email' => (string) AppSetting::getValue('support.email', ''),
                'whatsapp' => (string) AppSetting::getValue('support.whatsapp', ''),
            ],
        ]);
    }

    public function index(Request $request)
    {
        $tickets = SupportTicket::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['data' => $tickets]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'subject' => 'required|string|max:255',
            'body' => 'required|string',
        ]);

        $data['user_id'] = $request->user()->id;
        $data['status'] = 'OPEN';

        $ticket = SupportTicket::create($data);

        return response()->json(['data' => $ticket], 201);
    }

    public function show($id)
    {
        $ticket = SupportTicket::find($id);

        if (!$ticket) {
            return response()->json(['message' => 'Not found'], 404);
        }

        return response()->json(['data' => $ticket]);
    }

    public function adminIndex(Request $request)
    {
        $tickets = SupportTicket::with('user')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['data' => $tickets]);
    }

    public function adminReply(Request $request, $id)
    {
        $ticket = SupportTicket::find($id);

        if (!$ticket) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'admin_reply' => 'required|string',
            'status' => 'nullable|string|in:OPEN,CLOSED,PENDING',
        ]);

        $ticket->update([
            'admin_reply' => $data['admin_reply'],
            'status' => $data['status'] ?? 'CLOSED',
        ]);

        return response()->json(['data' => $ticket->fresh()]);
    }
}
