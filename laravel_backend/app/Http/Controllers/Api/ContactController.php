<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ContactController extends Controller
{
    /**
     * Public contact form (no auth). Records the enquiry to the log channel.
     * When real mail is configured, swap the Log::info for a Mailable.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email|max:160',
            'message' => 'required|string|max:2000',
        ]);

        Log::channel('stack')->info('Contact form submission', $data);

        return response()->json([
            'message' => 'Thanks! We received your message and will get back to you soon.',
        ], 201);
    }
}
