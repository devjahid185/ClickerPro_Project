<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FeatureFlag;
use Illuminate\Http\Request;

class EntitlementController extends Controller
{
    public function check(Request $request, $key)
    {
        $flag = FeatureFlag::where('key', $key)->first();

        if (!$flag || !$flag->is_enabled) {
            return response()->json(['allowed' => false, 'reason' => 'Feature not available']);
        }

        if ($flag->requires_pro && !$request->user()->isPro()) {
            return response()->json(['allowed' => false, 'reason' => 'PRO plan required']);
        }

        return response()->json(['allowed' => true]);
    }
}
