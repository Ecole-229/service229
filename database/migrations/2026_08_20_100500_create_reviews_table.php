<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();

            // Un avis est toujours laissé sur une mission terminée précise
            $table->foreignId('mission_id')->constrained('missions')->cascadeOnDelete();

            // Répétés ici pour interroger facilement "tous les avis d'un prestataire"
            // sans repasser par missions -> proposals -> service_requests
            $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('provider_profile_id')->constrained('provider_profiles')->cascadeOnDelete();

            $table->unsignedTinyInteger('note'); // note de 1 à 5
            $table->text('commentaire')->nullable();

            $table->timestamps();

            // Un seul avis possible par mission
            $table->unique('mission_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
