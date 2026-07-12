<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Persist the remaining device-side profile fields server-side. These lived
// only in the device's local DB, so the app had to merge them back after every
// login. On logout the local cache is wiped, and re-login pulled a server
// profile that never carried these columns — so whatsapp / studio address /
// specialization / VAT BIN silently vanished ("profile-এ কিছু এড করলে logout
// হলে সব চলে যায়"). Storing them here makes profile edits durable across
// logout, reinstall, and every device/web client.
//
// Nullable so every existing row is untouched.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'whatsapp')) {
                $table->string('whatsapp', 30)->nullable()->after('phone');
            }
            if (!Schema::hasColumn('users', 'studio_address')) {
                $table->string('studio_address', 500)->nullable()->after('business_name');
            }
            if (!Schema::hasColumn('users', 'specialization')) {
                $table->string('specialization', 120)->nullable()->after('studio_address');
            }
            if (!Schema::hasColumn('users', 'vat_bin')) {
                $table->string('vat_bin', 50)->nullable()->after('vat_label');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'whatsapp',
                'studio_address',
                'specialization',
                'vat_bin',
            ]);
        });
    }
};
