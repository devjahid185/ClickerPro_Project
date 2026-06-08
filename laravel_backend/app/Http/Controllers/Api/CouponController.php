<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use Illuminate\Http\Request;

class CouponController extends Controller
{
    public function apply(Request $request)
    {
        $data = $request->validate([
            'code' => 'required|string',
        ]);

        $coupon = Coupon::where('code', strtoupper($data['code']))
            ->where('is_active', true)
            ->first();

        if (!$coupon) {
            return response()->json(['message' => 'Invalid coupon code'], 422);
        }

        if ($coupon->expires_at && $coupon->expires_at->isPast()) {
            return response()->json(['message' => 'Coupon has expired'], 422);
        }

        if ($coupon->max_uses !== null && $coupon->uses >= $coupon->max_uses) {
            return response()->json(['message' => 'Coupon usage limit reached'], 422);
        }

        $coupon->increment('uses');

        return response()->json(['data' => $coupon->fresh()]);
    }

    public function index()
    {
        $coupons = Coupon::orderBy('created_at', 'desc')->get();
        return response()->json(['data' => $coupons]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'code' => 'required|string|unique:coupons,code',
            'type' => 'required|string|in:PERCENT,FLAT,PRO_DAYS',
            'value' => 'required|numeric|min:0',
            'max_uses' => 'nullable|integer|min:1',
            'expires_at' => 'nullable|date',
            'is_active' => 'nullable|boolean',
        ]);

        $data['code'] = strtoupper($data['code']);
        $data['is_active'] = $data['is_active'] ?? true;

        $coupon = Coupon::create($data);

        return response()->json(['data' => $coupon], 201);
    }

    public function update(Request $request, $id)
    {
        $coupon = Coupon::find($id);

        if (!$coupon) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'code' => 'nullable|string|unique:coupons,code,' . $id,
            'type' => 'nullable|string|in:PERCENT,FLAT,PRO_DAYS',
            'value' => 'nullable|numeric|min:0',
            'max_uses' => 'nullable|integer|min:1',
            'expires_at' => 'nullable|date',
            'is_active' => 'nullable|boolean',
        ]);

        if (isset($data['code'])) {
            $data['code'] = strtoupper($data['code']);
        }

        $coupon->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $coupon->fresh()]);
    }

    public function destroy($id)
    {
        $coupon = Coupon::find($id);

        if (!$coupon) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $coupon->delete();

        return response()->json(['message' => 'ok']);
    }
}
