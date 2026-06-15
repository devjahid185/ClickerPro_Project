<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds the rich booking detail fields that the mobile app captured but the
 * server never persisted (they lived only in the device's local DB). Without
 * these columns mobile↔web parity is impossible: a second device — or the
 * web app — can never see bride/groom, package economics, drive link, the
 * chief photographer, etc. Column names mirror the Flutter BookingDraft
 * fields in snake_case so server_wire maps 1:1.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->string('company_name')->nullable()->after('title');
            $table->string('bride_name')->nullable()->after('event_type');
            $table->string('groom_name')->nullable()->after('bride_name');

            $table->boolean('outdoor')->default(false)->after('venue');
            $table->string('outdoor_location')->nullable()->after('outdoor');
            $table->string('reporting_time')->nullable()->after('outdoor_location');
            $table->string('start_time')->nullable()->after('reporting_time');
            $table->string('end_time')->nullable()->after('start_time');
            $table->string('map_link')->nullable()->after('end_time');

            $table->decimal('coverage_hours', 8, 2)->nullable()->after('price');
            $table->decimal('extra_hour_rate', 10, 2)->nullable()->after('coverage_hours');
            $table->decimal('custom_price', 10, 2)->nullable()->after('extra_hour_rate');

            $table->string('drive_link')->nullable()->after('internal_notes');
            $table->text('requirements_note')->nullable()->after('drive_link');
            $table->string('chief_photographer_name')->nullable()->after('requirements_note');
            $table->boolean('hide_payment_from_team')->default(false)->after('chief_photographer_name');
        });
    }

    public function down(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropColumn([
                'company_name',
                'bride_name',
                'groom_name',
                'outdoor',
                'outdoor_location',
                'reporting_time',
                'start_time',
                'end_time',
                'map_link',
                'coverage_hours',
                'extra_hour_rate',
                'custom_price',
                'drive_link',
                'requirements_note',
                'chief_photographer_name',
                'hide_payment_from_team',
            ]);
        });
    }
};
