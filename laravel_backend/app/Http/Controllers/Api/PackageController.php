<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Package;
use Illuminate\Http\Request;

class PackageController extends Controller
{
    public function index(Request $request)
    {
        $packages = Package::where('owner_id', $request->user()->studioId())
            ->orderBy('name')
            ->get();

        return response()->json(['data' => $packages]);
    }

    /**
     * Keys that live in dedicated columns. Everything else the client sends
     * (price, discount, prints, album, delivery, trailers, full videos,
     * photographer / cinematographer counts, chief flag, items…) is stored
     * verbatim in the JSON `meta` bag so nothing is silently dropped.
     */
    private const COLUMN_KEYS = [
        'name', 'base_price', 'coverage_hours',
        'has_video', 'has_drone', 'has_album', 'notes',
    ];

    private function splitPayload(Request $request): array
    {
        $all = $request->all();
        // The web editor sends `price` (not `base_price`) — bridge it.
        $basePrice = $request->input('base_price', $request->input('price'));

        $columns = array_filter([
            'name' => $request->input('name'),
            'base_price' => $basePrice !== null ? (float) $basePrice : null,
            'coverage_hours' => $request->input('coverage_hours'),
            'has_video' => $request->input('has_video'),
            'has_drone' => $request->input('has_drone'),
            'has_album' => $request->input('has_album'),
            'notes' => $request->input('notes'),
        ], fn ($v) => $v !== null);

        // meta = everything that isn't a real column or a control field.
        $meta = collect($all)
            ->except(array_merge(self::COLUMN_KEYS, ['owner_id', 'id', '_method']))
            ->toArray();

        return [$columns, $meta];
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
        ]);

        [$columns, $meta] = $this->splitPayload($request);
        $columns['owner_id'] = $request->user()->studioId();
        $columns['base_price'] = $columns['base_price'] ?? 0;
        $columns['meta'] = $meta;

        $package = Package::create($columns);

        return response()->json(['data' => $package], 201);
    }

    public function update(Request $request, $id)
    {
        $package = Package::where('owner_id', $request->user()->studioId())->find($id);

        if (!$package) {
            return response()->json(['message' => 'Not found'], 404);
        }

        [$columns, $meta] = $this->splitPayload($request);
        // Merge new meta over the existing bag so partial PATCHes keep
        // previously-saved extended fields.
        $existingMeta = is_array($package->meta) ? $package->meta : [];
        $columns['meta'] = array_merge($existingMeta, $meta);

        $package->update($columns);

        return response()->json(['data' => $package->fresh()]);
    }

    public function destroy(Request $request, $id)
    {
        $package = Package::where('owner_id', $request->user()->studioId())->find($id);

        if (!$package) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $package->delete();

        return response()->json(['message' => 'ok']);
    }
}
