<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rent_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('gear_item_id')->constrained('gear_items')->cascadeOnDelete();
            $table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
            $table->string('direction');
            $table->string('rented_to')->nullable();
            $table->decimal('amount', 10, 2)->nullable();
            $table->timestamp('rented_at');
            $table->timestamp('returned_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rent_records');
    }
};
