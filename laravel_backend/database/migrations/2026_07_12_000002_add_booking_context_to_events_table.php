<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Separates a user's bookings by the ROLE they were created under.
 *
 * A single account can hold both an Owner and a Freelancer role and switch
 * between them (Profile → Change role). Heaven's requirement: switching role
 * must NOT carry over the previous role's bookings — "রোল চেইঞ্জ করলে আগের
 * রোলের সব ডাটা থাকে" was the bug. Because both roles resolve to the SAME
 * `owner_id`, the server used to return every event regardless of the active
 * role, so the client re-pulled the old role's data right after wiping it.
 *
 * `booking_context` stamps each event with the role that created it
 * ('OWNER' | 'FREELANCER'). The booking list then filters by the caller's
 * active role. Legacy rows (created before this column) are NULL and remain
 * visible to the Owner view so nothing already saved disappears.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->string('booking_context')->nullable()->after('owner_id');
            $table->index(['owner_id', 'booking_context']);
        });
    }

    public function down(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropIndex(['owner_id', 'booking_context']);
            $table->dropColumn('booking_context');
        });
    }
};
