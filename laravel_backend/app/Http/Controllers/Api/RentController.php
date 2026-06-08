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
            'gear_item_id' => 'required|integer|exists:gear_items,id',
            'direction' => 'required|string|in:IN,OUT',
            'rented_to' => 'nullable|string|max:255',
            'amount' => 'nullable|numeric|min:0',
            'rented_at' => 'required|date',
            'returned_at' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        $data['owner_id'] = $request->user()->id;

        $record = RentRecord::create($data);

        // Update gear availability
        $gear = GearItem::find($data['gear_item_id']);
        if ($gear) {
            $gear->update(['is_available' => $data['direction'] === 'IN']);
        }

        return response()->json(['data' => $record], 201);
    }
}
