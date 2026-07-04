<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GearItem;
use App\Models\RentRecord;
use Illuminate\Http\Request;

class RentController extends Controller
{
    public function index($gearId)
    {
        $records = RentRecord::where('gear_item_id', $gearId)
            ->orderBy('rented_at', 'desc')
            ->get();

        return response()->json(['data' => $records]);
    }

    // All rent records for the owner, with gear name — powers the Rent page.
    public function all(Request $request)
    {
        $records = RentRecord::where('owner_id', $request->user()->id)
            ->with('gearItem:id,name')
            ->orderBy('rented_at', 'desc')
            ->get();

        return response()->json(['data' => $records]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'gear_item_id' => 'nullable|integer|exists:gear_items,id',
            'direction' => 'required|string|in:IN,OUT',
            'rented_to' => 'nullable|string|max:255',
            'counterparty_phone' => 'nullable|string|max:32',
            'amount' => 'nullable|numeric|min:0',
            'rented_at' => 'required|date',
            'return_by' => 'nullable|date',
            'returned_at' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        $data['owner_id'] = $request->user()->id;

        $record = RentRecord::create($data);

        // Update gear availability
        if (!empty($data['gear_item_id'])) {
            $gear = GearItem::find($data['gear_item_id']);
            if ($gear) {
                $gear->update(['is_available' => $data['direction'] === 'IN']);
            }
        }

        return response()->json(['data' => $record], 201);
    }

    /** Mark a rent record returned (or amend it) — owner only. */
    public function update(Request $request, $id)
    {
        $record = RentRecord::where('owner_id', $request->user()->id)->find($id);

        if (!$record) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'returned_at' => 'nullable|date',
            'amount' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $record->update(array_filter($data, fn($v) => $v !== null));

        // Returning gear makes it available again.
        if (!empty($data['returned_at']) && $record->gear_item_id) {
            GearItem::where('id', $record->gear_item_id)
                ->update(['is_available' => true]);
        }

        return response()->json(['data' => $record->fresh()]);
    }
}
