<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Package;
use Illuminate\Http\Request;

class PackageController extends Controller
{
    public function index(Request $request)
    {
        $packages = Package::where('owner_id', $request->user()->id)
            ->orderBy('name')
            ->get();

        return response()->json(['data' => $packages]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'base_price' => 'required|numeric|min:0',
            'coverage_hours' => 'nullable|integer|min:0',
            'has_video' => 'nullable|boolean',
            'has_drone' => 'nullable|boolean',
            'has_album' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        $data['owner_id'] = $request->user()->id;

        $package = Package::create($data);

        return response()->json(['data' => $package], 201);
    }

    public function update(Request $request, $id)
    {
        $package = Package::where('owner_id', $request->user()->id)->find($id);

        if (!$package) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'name' => 'nullable|string|max:255',
            'base_price' => 'nullable|numeric|min:0',
            'coverage_hours' => 'nullable|integer|min:0',
            'has_video' => 'nullable|boolean',
            'has_drone' => 'nullable|boolean',
            'has_album' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        $package->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $package->fresh()]);
    }

    public function destroy(Request $request, $id)
    {
        $package = Package::where('owner_id', $request->user()->id)->find($id);

        if (!$package) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $package->delete();

        return response()->json(['message' => 'ok']);
    }
}
