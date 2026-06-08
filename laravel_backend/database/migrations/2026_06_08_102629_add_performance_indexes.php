<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Additive-only: add indexes to speed up the hottest filtered queries.
     * No columns/data changed. Fully reversible.
     */
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table) {
            // Booking lists filter by owner + date range, and owner + status.
            // Composite indexes match the WHERE owner_id … AND (date|status) shape.
            $table->index(['owner_id', 'date'], 'events_owner_date_idx');
            $table->index(['owner_id', 'status'], 'events_owner_status_idx');
        });

        Schema::table('payments', function (Blueprint $table) {
            // Monthly revenue grouping aggregates over created_at.
            $table->index('created_at', 'payments_created_at_idx');
        });
    }

    public function down(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropIndex('events_owner_date_idx');
            $table->dropIndex('events_owner_status_idx');
        });

        Schema::table('payments', function (Blueprint $table) {
            $table->dropIndex('payments_created_at_idx');
        });
    }
};
