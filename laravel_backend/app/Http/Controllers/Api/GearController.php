<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GearItem;
use Illuminate\Http\Request;

class GearController extends Controller
{
    public function index(Request $request)
    {
        $items = GearItem::where('owner_id', $request->user()->id)
            ->orderBy('name')
            ->get();

        return response()->json(['data' => $items]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'nullable|string|max:100',
            'serial_number' => 'nullable|string|max:100',
            'condition' => 'nullable|string|max:50',
            'purchase_value' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
            'is_available' => 'nullable|boolean',
        ]);

        $data['owner_id'] = $request->user()->id;
        $data['condition'] = $data['condition'] ?? 'GOOD';

        $item = GearItem::create($data);

        return response()->json(['data' => $item], 201);
    }

    public function update(Request $request, $id)
    {
        $item = GearItem::where('owner_id', $request->user()->id)->find($id);

        if (!$item) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'name' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:100',
            'serial_number' => 'nullable|string|max:100',
            'condition' => 'nullable|string|max:50',
            'purchase_value' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
            'is_available' => 'nullable|boolean',
        ]);

        $item->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $item->fresh()]);
    }

    public function destroy(Request $request, $id)
    {
        $item = GearItem::where('owner_id', $request->user()->id)->find($id);

        if (!$item) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $item->delete();

        return response()->json(['message' => 'ok']);
    }
}
