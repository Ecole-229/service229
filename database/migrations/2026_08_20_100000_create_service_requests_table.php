<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_requests', function (Blueprint $table) {
            $table->id();

            // Client qui crée la demande
            $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();

            // Catégorie + zone (référentiel géré par Mme Titilola)
            $table->foreignId('service_category_id')->constrained('service_categories')->restrictOnDelete();
            $table->foreignId('zone_id')->constrained('zones')->restrictOnDelete();

            // Renseigné uniquement en Mode 1 (recherche directe / contact direct)
            // Reste null en Mode 2 (publication d'un besoin ouvert)
            $table->foreignId('provider_profile_id')->nullable()
                ->constrained('provider_profiles')->nullOnDelete();

            $table->string('title');
            $table->text('description')->nullable();

            // Statuts figés — section 4.1 du document de référence
            $table->enum('status', [
                'draft',
                'published',
                'matched',
                'assigned',
                'cancelled',
                'expired',
                'closed',
            ])->default('draft');

            $table->timestamps();

            $table->index(['status', 'service_category_id', 'zone_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_requests');
    }
};
