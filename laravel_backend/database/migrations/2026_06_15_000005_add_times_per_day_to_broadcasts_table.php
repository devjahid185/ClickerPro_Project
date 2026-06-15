<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * How many times per day a broadcast may pop up for a user. Set per broadcast
 * in the admin panel; the mobile app tracks per-day show counts and stops once
 * the cap is reached. Defaults to 1.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('broadcasts', function (Blueprint $table) {
            $table->unsignedSmallInteger('times_per_day')->default(1)->after('button_label');
        });
    }

    public function down(): void
    {
        Schema::table('broadcasts', function (Blueprint $table) {
            $table->dropColumn('times_per_day');
        });
    }
};
