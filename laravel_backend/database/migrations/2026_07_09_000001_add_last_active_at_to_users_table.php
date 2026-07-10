<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds `last_active_at` so the admin console can show "last seen N days ago"
 * and classify accounts as Active (used the app recently) vs Inactive.
 *
 * `created_at` already gives the registration date; this fills the "last
 * used" gap the users table had. Updated on each authenticated API request
 * by TouchLastActive middleware (throttled to once/15 min per user).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('last_active_at')->nullable()->after('is_active');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('last_active_at');
        });
    }
};
