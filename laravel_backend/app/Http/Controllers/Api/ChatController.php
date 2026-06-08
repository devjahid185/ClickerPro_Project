<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatGroup;
use App\Models\ChatMessage;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function groups(Request $request)
    {
        $groups = ChatGroup::where('owner_id', $request->user()->id)
            ->orderBy('name')
            ->get();

        return response()->json(['data' => $groups]);
    }

    public function createGroup(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
        ]);

        $data['owner_id'] = $request->user()->id;
        $group = ChatGroup::create($data);

        return response()->json(['data' => $group], 201);
    }

    public function messages(Request $request, $groupId)
    {
        $messages = ChatMessage::where('group_id', $groupId)
            ->with('sender')
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json(['data' => $messages]);
    }

    public function sendMessage(Request $request, $groupId)
    {
        $data = $request->validate([
            'body' => 'required|string',
        ]);

        $message = ChatMessage::create([
            'group_id' => $groupId,
            'sender_id' => $request->user()->id,
            'body' => $data['body'],
        ]);

        return response()->json(['data' => $message->load('sender')], 201);
    }
}
