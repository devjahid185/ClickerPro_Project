<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use Illuminate\Http\Request;

/**
 * Admin → Coupons (Blade). Full CRUD against the Coupon model, mirroring
 * the API CouponController's validation rules.
 */
class CouponsController extends Controller
{
    public const TYPES = ['PERCENT', 'FLAT', 'PRO_DAYS'];

    public function index()
    {
        return view('admin.coupons.index', [
            'coupons' => Coupon::orderBy('created_at', 'desc')->get(),
            'types'   => self::TYPES,
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'code'       => ['required', 'string', 'unique:coupons,code'],
            'type'       => ['required', 'string', 'in:' . implode(',', self::TYPES)],
            'value'      => ['required', 'numeric', 'min:0'],
            'max_uses'   => ['nullable', 'integer', 'min:1'],
            'expires_at' => ['nullable', 'date'],
            'is_active'  => ['nullable', 'boolean'],
        ]);
        $data['code'] = strtoupper($data['code']);
        $data['is_active'] = $request->boolean('is_active', true);

        Coupon::create($data);

        return redirect()->route('admin.coupons')->with('status', "Coupon {$data['code']} created.");
    }

    public function toggle($id)
    {
        $coupon = Coupon::findOrFail($id);
        $coupon->update(['is_active' => ! $coupon->is_active]);

        return back()->with('status', "Coupon {$coupon->code} " . ($coupon->is_active ? 'activated' : 'deactivated') . '.');
    }

    public function destroy($id)
    {
        $coupon = Coupon::findOrFail($id);
        $code = $coupon->code;
        $coupon->delete();

        return back()->with('status', "Coupon {$code} deleted.");
    }
}
