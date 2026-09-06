<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('provider_zones', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_profile_id')
                ->constrained('provider_profiles')
                ->cascadeOnDelete();

            $table->foreignId('zone_id')
                ->constrained('zones')
                ->cascadeOnDelete();

            $table->timestamps();

            $table->unique(['provider_profile_id', 'zone_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_zones');
    }
};
