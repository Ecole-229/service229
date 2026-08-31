<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_request_photos', function (Blueprint $table) {
            $table->id();

            $table->foreignId('service_request_id')->constrained('service_requests')->cascadeOnDelete();

            // Chemin relatif sur le disque "public" (ex: service-requests/xyz.jpg)
            $table->string('chemin_fichier');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_request_photos');
    }
};
