<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Email-targeted team invites: when `target_email` is set the invite can
 * only be redeemed by the registered user with that email (in-app
 * accept/decline). Plain passcode invites keep `target_email` NULL.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('team_invite_codes', function (Blueprint $table) {
            $table->string('target_email')->nullable()->after('code')->index();
        });
    }

    public function down(): void
    {
        Schema::table('team_invite_codes', function (Blueprint $table) {
            $table->dropColumn('target_email');
        });
    }
};
