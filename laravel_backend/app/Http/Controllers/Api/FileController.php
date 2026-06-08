<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class FileController extends Controller
{
    public function upload(Request $request)
    {
        // Allow-list safe document/image types only — blocks .php/.svg/.html
        // and other executable or script-bearing uploads.
        $request->validate([
            'file' => 'required|file|max:10240|mimes:jpg,jpeg,png,webp,gif,pdf',
        ]);

        $file = $request->file('file');
        // Derive the extension from the validated MIME guess, not the
        // client-supplied name, then store under a random UUID filename.
        $extension = $file->extension() ?: $file->getClientOriginalExtension();
        $filename = Str::uuid() . '.' . $extension;

        $path = $file->storeAs('uploads', $filename, 'public');

        $url = Storage::url($path);

        return response()->json([
            'data' => [
                'path' => $path,
                'url' => $url,
                'filename' => $filename,
            ],
        ]);
    }

    public function destroy(Request $request)
    {
        $data = $request->validate([
            'path' => 'required|string',
        ]);

        if (Storage::disk('public')->exists($data['path'])) {
            Storage::disk('public')->delete($data['path']);
        }

        return response()->json(['message' => 'ok']);
    }

    // Admin: list all uploaded files with size + modified time.
    public function adminIndex()
    {
        $disk = Storage::disk('public');
        $files = $disk->exists('uploads') ? $disk->files('uploads') : [];

        $totalBytes = 0;
        $items = collect($files)->map(function ($path) use ($disk, &$totalBytes) {
            $size = $disk->size($path);
            $totalBytes += $size;
            return [
                'name' => basename($path),
                'url' => $disk->url($path),
                'size' => $size,
                'modified' => date('c', $disk->lastModified($path)),
            ];
        })->values();

        return response()->json(['data' => $items, 'totalBytes' => $totalBytes]);
    }

    public function adminDestroy(Request $request, $name)
    {
        $path = 'uploads/' . $name;
        if (Storage::disk('public')->exists($path)) {
            Storage::disk('public')->delete($path);
        }
        return response()->json(['message' => 'ok']);
    }
}
