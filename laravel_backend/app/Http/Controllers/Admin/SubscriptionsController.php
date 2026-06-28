<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FeatureFlag;

/**
 * Admin → Subscriptions & Features (Blade). Toggle which features require a
 * PRO plan, against the FeatureFlag model.
 */
class SubscriptionsController extends Controller
{
    public function index()
    {
        $features = FeatureFlag::orderBy('key')->get();

        return view('admin.subscriptions.index', [
            'features'  => $features,
            'paidCount' => $features->where('requires_pro', true)->count(),
        ]);
    }

    public function toggle($key)
    {
        $flag = FeatureFlag::where('key', $key)->firstOrFail();
        $flag->update(['requires_pro' => ! $flag->requires_pro]);

        return back()->with('status', "“{$flag->label}” is now " . ($flag->requires_pro ? 'PRO-only' : 'free') . '.');
    }
}
