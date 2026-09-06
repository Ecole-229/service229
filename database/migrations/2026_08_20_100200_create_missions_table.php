<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('missions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('service_request_id')->constrained('service_requests')->restrictOnDelete();
            $table->foreignId('proposal_id')->constrained('proposals')->restrictOnDelete();

            // Dénormalisés depuis service_request/proposal pour des requêtes simples
            $table->foreignId('client_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('provider_profile_id')->constrained('provider_profiles')->restrictOnDelete();

            // Statuts figés — section 4.3 du document de référence
            $table->enum('status', [
                'pending',
                'in_progress',
                'awaiting_confirmation',
                'completed',
                'cancelled',
                'disputed',
            ])->default('pending');

            // Paiement hors plateforme — section 2.4 : simple booléen de suivi
            $table->boolean('paiementEffectue')->default(false);

            $table->timestamps();

            $table->unique('service_request_id');
            $table->unique('proposal_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('missions');
    }
};
