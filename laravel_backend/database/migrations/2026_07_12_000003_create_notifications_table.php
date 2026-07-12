<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Per-user in-app notifications.
 *
 * The app's notifications screen (GET /api/notifications) expects real
 * per-user records — { id, category, message, read, sentAt, deeplink }. Until
 * now that endpoint only returned admin Broadcasts, so events like a client
 * self-booking never showed up in the bell: the only path was an FCM push,
 * which silently no-ops on hosting without Firebase credentials. That was the
 * "self-booking করলে owner-এ notification যায় না" bug.
 *
 * This table gives every user a durable notification inbox that works with or
 * without push. `read_at` NULL means unread.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            // Free-form so new categories don't need a schema change:
            // OPERATIONS | PAYMENT | REEDIT | ANNOUNCEMENT | WISH | OTHER.
            $table->string('category')->default('OTHER');
            $table->text('message');
            // In-app deep link (route + args), e.g. "pending_public_bookings".
            $table->string('deeplink')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
