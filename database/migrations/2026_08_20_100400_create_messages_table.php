<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();

            $table->foreignId('conversation_id')->constrained('conversations')->cascadeOnDelete();

            // Celui qui envoie le message (client OU prestataire, tous deux dans users)
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();

            $table->text('content');

            // Pour savoir si le destinataire a lu le message (utile pour les notifications)
            $table->timestamp('read_at')->nullable();

            $table->timestamps();

            $table->index('conversation_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};
