<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Packages carried only a handful of columns (base_price, coverage_hours,
 * has_video/drone/album, notes). The web + mobile package editors send many
 * more fields — discount, prints, album text, delivery, trailers, full
 * videos, and now photographer / cinematographer counts + a chief flag.
 *
 * Rather than a column per field, store the full extended package shape in
 * a single JSON `meta` column. No data is lost and new fields never need
 * another migration.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('packages', function (Blueprint $table) {
            if (!Schema::hasColumn('packages', 'meta')) {
                $table->json('meta')->nullable()->after('notes');
            }
        });
    }

    public function down(): void
    {
        Schema::table('packages', function (Blueprint $table) {
            if (Schema::hasColumn('packages', 'meta')) {
                $table->dropColumn('meta');
            }
        });
    }
};
