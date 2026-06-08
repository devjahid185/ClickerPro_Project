<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    public function index(Request $request)
    {
        $query = Expense::where('owner_id', $request->user()->id)
            ->orderBy('date', 'desc');

        if ($request->has('event_id') && $request->event_id) {
            $query->where('event_id', $request->event_id);
        }

        return response()->json(['data' => $query->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'event_id' => 'nullable|integer|exists:events,id',
            'title' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0',
            'category' => 'nullable|string|max:100',
            'note' => 'nullable|string',
            'receipt_url' => 'nullable|string',
            'date' => 'required|date',
        ]);

        $data['owner_id'] = $request->user()->id;
        $expense = Expense::create($data);

        return response()->json(['data' => $expense], 201);
    }

    public function update(Request $request, $id)
    {
        $expense = Expense::where('owner_id', $request->user()->id)->find($id);

        if (!$expense) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'event_id' => 'nullable|integer|exists:events,id',
            'title' => 'nullable|string|max:255',
            'amount' => 'nullable|numeric|min:0',
            'category' => 'nullable|string|max:100',
            'note' => 'nullable|string',
            'receipt_url' => 'nullable|string',
            'date' => 'nullable|date',
        ]);

        $expense->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $expense->fresh()]);
    }

    public function destroy(Request $request, $id)
    {
        $expense = Expense::where('owner_id', $request->user()->id)->find($id);

        if (!$expense) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $expense->delete();

        return response()->json(['message' => 'ok']);
    }
}
