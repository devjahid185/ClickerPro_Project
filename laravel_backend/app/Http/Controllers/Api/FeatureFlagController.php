<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FeatureFlag;
use Illuminate\Http\Request;

class FeatureFlagController extends Controller
{
    public function index()
    {
        $flags = FeatureFlag::orderBy('key')->get();
        return response()->json(['data' => $flags]);
    }

    public function update(Request $request, $id)
    {
        // Accept either numeric id or string key (frontend uses key).
        $flag = is_numeric($id)
            ? FeatureFlag::find($id)
            : FeatureFlag::where('key', $id)->first();

        if (!$flag) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'requires_pro' => 'nullable|boolean',
            'is_enabled' => 'nullable|boolean',
            'label' => 'nullable|string|max:255',
        ]);

        $flag->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $flag->fresh()]);
    }
}
