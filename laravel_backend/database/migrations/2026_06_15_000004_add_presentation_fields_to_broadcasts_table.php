<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Presentation fields the admin panel's broadcast composer already collects
 * (priority, type, image, deep-link + button) but the events table never
 * stored — so they silently vanished on save. Adding the columns lets the
 * BroadcastResource expose real values instead of hard-coded defaults.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('broadcasts', function (Blueprint $table) {
            $table->string('priority')->default('Normal')->after('body');
            $table->string('type')->default('Announcement')->after('priority');
            $table->string('image_url')->nullable()->after('type');
            $table->string('link')->nullable()->after('image_url');
            $table->string('button_label')->nullable()->after('link');
        });
    }

    public function down(): void
    {
        Schema::table('broadcasts', function (Blueprint $table) {
            $table->dropColumn(['priority', 'type', 'image_url', 'link', 'button_label']);
        });
    }
};
