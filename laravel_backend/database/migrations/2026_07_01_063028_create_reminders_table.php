<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Guard: an earlier migration (2024_01_01_000014) already creates the
        // `reminders` table. Without this check, running the full migration set
        // on a fresh DB (e.g. tests / a clean deploy) fails with
        // "table reminders already exists". Idempotent so both orderings work.
        if (Schema::hasTable('reminders')) {
            return;
        }

        Schema::create('reminders', function (Blueprint $table) {
            $table->id();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reminders');
    }
};
