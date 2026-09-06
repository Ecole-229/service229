<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();

            // Le destinataire de la notification
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();

            // Type fermé et connu à l'avance (liste définie dans le code, pas en base)
            // ex: nouvelle_proposal, proposal_acceptee, mission_terminee, nouveau_message, nouvel_avis
            $table->string('type');

            $table->string('message');

            // Lien vers la page concernée côté Vue (ex: /missions/12)
            // Simple pour l'instant, pourra devenir polymorphe plus tard si besoin
            $table->string('lien_associe')->nullable();

            $table->boolean('lu')->default(false);

            $table->timestamps();

            $table->index(['user_id', 'lu']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
