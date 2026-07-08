<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Persist the studio's money settings (currency + tax) server-side so they
// survive a reinstall and stay in sync across the owner's devices and the web
// app. Previously these lived only in the device's SharedPreferences, so a new
// device fell back to the BDT default and any VAT setup had to be re-entered.
//
// Nullable with sensible defaults so every existing row keeps rendering BDT
// with tax off — exactly the prior behaviour.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // ISO-4217 code, e.g. BDT / USD / EUR. Null → client default (BDT).
            $table->string('currency_code', 3)->nullable()->after('bio');
            // Tax line on invoices.
            $table->boolean('vat_enabled')->default(false)->after('currency_code');
            // Rate as a percentage, e.g. 15.00. decimal(5,2) covers 0–999.99%.
            $table->decimal('vat_rate_pct', 5, 2)->default(0)->after('vat_enabled');
            // What the tax is called here: VAT / GST / Tax / SST…
            $table->string('vat_label', 20)->nullable()->after('vat_rate_pct');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'currency_code',
                'vat_enabled',
                'vat_rate_pct',
                'vat_label',
            ]);
        });
    }
};
