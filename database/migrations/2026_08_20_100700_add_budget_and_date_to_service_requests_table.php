<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_requests', function (Blueprint $table) {
            // Champs présents dans la maquette (web + mobile), absents du
            // document texte initial — ajoutés en nullable, aucune donnée
            // existante affectée.
            $table->decimal('budget_estime', 10, 2)->nullable()->after('description');
            $table->date('date_intervention')->nullable()->after('budget_estime');
        });
    }

    public function down(): void
    {
        Schema::table('service_requests', function (Blueprint $table) {
            $table->dropColumn(['budget_estime', 'date_intervention']);
        });
    }
};
