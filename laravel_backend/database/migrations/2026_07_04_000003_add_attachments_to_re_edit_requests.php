<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Re-edit requests can now carry reference images (screenshots of the
// photos that need fixing). URLs come from POST /api/files/upload.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('re_edit_requests', function (Blueprint $table) {
            $table->json('attachments')->nullable()->after('description');
        });
    }

    public function down(): void
    {
        Schema::table('re_edit_requests', function (Blueprint $table) {
            $table->dropColumn('attachments');
        });
    }
};
