<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Persist a team member's payout details (bKash / bank) so a studio owner can
// see how to pay them from the member-profile sheet. Previously these lived
// only on the member's device, so the owner never saw them.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('bkash_number')->nullable()->after('phone');
            $table->string('bank_details')->nullable()->after('bkash_number');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['bkash_number', 'bank_details']);
        });
    }
};
