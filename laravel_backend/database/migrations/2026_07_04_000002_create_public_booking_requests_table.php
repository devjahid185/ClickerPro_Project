<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Client self-booking submissions used to be written straight into
// `events`, so they appeared in the owner's booking list with no review
// step and no notification. They now land here as PENDING requests; the
// owner approves (→ an Event is created and event_id links back) or
// rejects from the Pending Requests screen.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('public_booking_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
            $table->string('name');
            $table->string('phone', 32)->nullable();
            $table->string('email')->nullable();
            $table->string('event_type', 100)->nullable();
            $table->date('date');
            $table->string('venue')->nullable();
            $table->foreignId('package_id')->nullable()->constrained('packages')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->string('status', 20)->default('PENDING'); // PENDING | APPROVED | REJECTED
            $table->foreignId('event_id')->nullable()->constrained('events')->nullOnDelete();
            $table->timestamps();

            $table->index(['owner_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('public_booking_requests');
    }
};
