<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PettyCashEntry;
use Illuminate\Http\Request;

class PettyCashController extends Controller
{
    public function index(Request $request)
    {
        $entries = PettyCashEntry::where('owner_id', $request->user()->id)
            ->orderBy('date', 'desc')
            ->get();

        return response()->json(['data' => $entries]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'category' => 'nullable|string|in:transport,food,print,phone,misc',
            'amount' => 'required|numeric|min:0',
            'date' => 'nullable|date',
            'note' => 'nullable|string',
        ]);

        $data['owner_id'] = $request->user()->id;
        $data['category'] = $data['category'] ?? 'misc';
        $data['date'] = $data['date'] ?? now()->toDateString();

        $entry = PettyCashEntry::create($data);

        return response()->json(['data' => $entry], 201);
    }

    public function update(Request $request, $id)
    {
        $entry = PettyCashEntry::where('owner_id', $request->user()->id)->find($id);
        if (!$entry) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'title' => 'nullable|string|max:255',
            'category' => 'nullable|string|in:transport,food,print,phone,misc',
            'amount' => 'nullable|numeric|min:0',
            'date' => 'nullable|date',
            'note' => 'nullable|string',
        ]);

        $entry->update(array_filter($data, fn ($v) => $v !== null));

        return response()->json(['data' => $entry->fresh()]);
    }

    public function destroy(Request $request, $id)
    {
        $entry = PettyCashEntry::where('owner_id', $request->user()->id)->find($id);
        if (!$entry) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $entry->delete();

        return response()->json(['message' => 'ok']);
    }
}
