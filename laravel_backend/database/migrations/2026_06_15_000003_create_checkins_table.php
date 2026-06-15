<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Freelancer live check-in records (FL-09). A freelancer taps "I'm Here"
 * on event day; the owner sees status and late arrivals. One row per
 * (freelancer, event) — re-checking in updates the same row.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('checkins', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('event_id')->constrained('events')->cascadeOnDelete();
            $table->timestamp('checkin_time');
            $table->timestamp('expected_time')->nullable();
            $table->string('status')->default('checkedIn'); // checkedIn|late|missed
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'event_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('checkins');
    }
};
