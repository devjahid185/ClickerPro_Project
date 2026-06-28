<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Api\FileController;
use App\Http\Controllers\Controller;

/**
 * Admin → Files (Blade). Lists uploaded files (reusing FileController) and
 * allows deletion.
 */
class FilesController extends Controller
{
    public function index(FileController $api)
    {
        $payload = $api->adminIndex()->getData(true);

        return view('admin.files.index', [
            'files'      => $payload['data'] ?? [],
            'totalBytes' => $payload['totalBytes'] ?? 0,
        ]);
    }

    public function destroy($name, FileController $api)
    {
        $api->adminDestroy($name);
        return back()->with('status', "File “{$name}” deleted.");
    }
}
