<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds an optional Facebook profile / page link to waitlist entries so the
 * studio can reach a prospective client on Messenger, alongside the phone.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('waitlists', function (Blueprint $table) {
            $table->string('facebook_link')->nullable()->after('notes');
        });
    }

    public function down(): void
    {
        Schema::table('waitlists', function (Blueprint $table) {
            $table->dropColumn('facebook_link');
        });
    }
};
