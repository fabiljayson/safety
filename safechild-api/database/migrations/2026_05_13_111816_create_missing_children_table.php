<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('missing_children', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->integer('age');
            $table->string('photo_url')->nullable();
            $table->text('description')->nullable();
            $table->string('last_clothes')->nullable();
            $table->enum('status', ['missing', 'found'])->default('missing');
            $table->decimal('disappearance_lat', 10, 8);
            $table->decimal('disappearance_lng', 11, 8);
            $table->timestamp('disappeared_at');
            $table->string('alert_type')->default('child_missing');
            $table->boolean('is_verified')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('missing_children');
    }
};
