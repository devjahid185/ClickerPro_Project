<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Owner opt-in flag for showing payment figures (total/advance/due) on the
 * shared event-details card the owner sends to the team and freelancers.
 *
 * Default OFF: shared event details never expose money unless the owner
 * explicitly turns this on for a booking. (Distinct from the client invoice,
 * which always shows payment.)
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->boolean('show_payment_in_share')
                ->default(false)
                ->after('hide_payment_from_team');
        });
    }

    public function down(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropColumn('show_payment_in_share');
        });
    }
};
