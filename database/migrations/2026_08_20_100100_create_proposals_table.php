<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('proposals', function (Blueprint $table) {
            $table->id();

            $table->foreignId('service_request_id')->constrained('service_requests')->cascadeOnDelete();
            $table->foreignId('provider_profile_id')->constrained('provider_profiles')->cascadeOnDelete();

            // "un Proposal (devis) contenant montant, délai et description" — section 2.3
            $table->decimal('montant', 10, 2);
            $table->string('delai'); // ex: "3 jours", "sous 48h" — texte libre du prestataire
            $table->text('description');

            // Statuts figés — section 4.2 du document de référence
            $table->enum('status', [
                'pending',
                'accepted',
                'rejected',
                'withdrawn',
            ])->default('pending');

            $table->timestamps();

            // Un prestataire ne peut avoir qu'un devis actif par demande
            $table->unique(['service_request_id', 'provider_profile_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('proposals');
    }
};
