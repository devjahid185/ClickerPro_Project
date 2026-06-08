<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Faq;
use Illuminate\Http\Request;

class FaqController extends Controller
{
    public function index()
    {
        $faqs = Faq::where('is_active', true)->orderBy('created_at')->get();
        return response()->json(['data' => $faqs]);
    }

    public function adminIndex()
    {
        $faqs = Faq::orderBy('created_at')->get();
        return response()->json(['data' => $faqs]);
    }

    public function adminStore(Request $request)
    {
        $data = $request->validate([
            'question' => 'required|string',
            'answer' => 'required|string',
            'is_active' => 'nullable|boolean',
        ]);

        $data['is_active'] = $data['is_active'] ?? true;
        $faq = Faq::create($data);

        return response()->json(['data' => $faq], 201);
    }

    public function adminUpdate(Request $request, $id)
    {
        $faq = Faq::find($id);

        if (!$faq) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'question' => 'nullable|string',
            'answer' => 'nullable|string',
            'is_active' => 'nullable|boolean',
        ]);

        $faq->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $faq->fresh()]);
    }

    public function adminDestroy($id)
    {
        $faq = Faq::find($id);

        if (!$faq) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $faq->delete();

        return response()->json(['message' => 'ok']);
    }
}
