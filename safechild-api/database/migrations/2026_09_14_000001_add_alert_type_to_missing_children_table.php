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
        // Guard: the column may already exist on databases where this
        // migration was applied outside of the migrations table.
        if (Schema::hasColumn('missing_children', 'alert_type')) {
            return;
        }

        Schema::table('missing_children', function (Blueprint $table) {
            $table->string('alert_type')->default('child_missing')->after('user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('missing_children', function (Blueprint $table) {
            $table->dropColumn('alert_type');
        });
    }
};
