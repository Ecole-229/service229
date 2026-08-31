<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();

            // Toujours nullable : le duo peut discuter "de tout et de rien"
            // avant même que le client ne formalise une demande.
            // Sert de référence à LA demande en cours de discussion (facultatif,
            // ne bloque rien si la conversation dérive vers un autre sujet ensuite).
            $table->foreignId('service_request_id')->nullable()
                ->constrained('service_requests')->nullOnDelete();

            $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('provider_profile_id')->constrained('provider_profiles')->cascadeOnDelete();

            $table->timestamps();

            // Un seul fil de discussion possible entre un client et un prestataire donné,
            // peu importe le nombre de demandes qu'ils traiteront ensemble dans le temps.
            $table->unique(['client_id', 'provider_profile_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conversations');
    }
};
