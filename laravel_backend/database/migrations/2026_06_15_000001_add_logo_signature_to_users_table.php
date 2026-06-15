<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Persist the studio logo and the owner's digital signature so they survive a
// reload (previously the app showed "Uploaded" but nothing was saved server
// side, so it reverted to "Not set" — the owner could never tell if it stuck).
// Stored as text because the clients may send a remote URL or a base64
// data-URI; either fits in a text column.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->text('logo_url')->nullable()->after('avatar');
            $table->text('signature_url')->nullable()->after('logo_url');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['logo_url', 'signature_url']);
        });
    }
};
