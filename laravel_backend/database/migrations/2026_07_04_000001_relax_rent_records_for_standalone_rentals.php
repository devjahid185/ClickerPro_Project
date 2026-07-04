<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// The Rent page lets owners log rentals that are not tied to a gear item
// in inventory (e.g. renting IN someone else's camera). gear_item_id was
// required at create time, so every save from the standalone Add Rent
// sheet failed validation. It is now optional. return_by and
// counterparty_phone previously lived only on the device and were lost
// on reinstall — they get real columns.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rent_records', function (Blueprint $table) {
            $table->foreignId('gear_item_id')->nullable()->change();
            $table->timestamp('return_by')->nullable()->after('rented_at');
            $table->string('counterparty_phone', 32)->nullable()->after('rented_to');
        });
    }

    public function down(): void
    {
        Schema::table('rent_records', function (Blueprint $table) {
            $table->dropColumn(['return_by', 'counterparty_phone']);
            $table->foreignId('gear_item_id')->nullable(false)->change();
        });
    }
};
