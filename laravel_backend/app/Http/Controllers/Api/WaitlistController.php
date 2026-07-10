<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Waitlist;
use Illuminate\Http\Request;

class WaitlistController extends Controller
{
    public function index(Request $request)
    {
        $items = Waitlist::where('owner_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['data' => $items]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:255',
            'date_requested' => 'nullable|date',
            'notes' => 'nullable|string',
            'facebook_link' => 'nullable|string|max:500',
        ]);

        $data['owner_id'] = $request->user()->id;
        $item = Waitlist::create($data);

        return response()->json(['data' => $item], 201);
    }

    public function destroy(Request $request, $id)
    {
        $item = Waitlist::where('owner_id', $request->user()->id)->find($id);

        if (!$item) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $item->delete();

        return response()->json(['message' => 'ok']);
    }
}
