<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Lets the admin console mark a crash/bug as handled. `resolved_at` doubles as
// the flag (null = still open) and the audit timestamp; the index keeps the
// "unresolved first" admin list fast as the table grows.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('crash_reports', function (Blueprint $table) {
            $table->timestamp('resolved_at')->nullable()->after('app_version');
            $table->index(['resolved_at', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::table('crash_reports', function (Blueprint $table) {
            $table->dropIndex(['resolved_at', 'created_at']);
            $table->dropColumn('resolved_at');
        });
    }
};
