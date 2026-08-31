<?php
namespace Database\Seeders;

use App\Models\Proposal;
use App\Models\ProviderProfile;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Models\Zone;
use Illuminate\Database\Seeder;

class ScenarioCarreleurTankpeSeeder extends Seeder
{
    public function run(): void
    {
        $carrelage = ServiceCategory::firstOrCreate(['nom' => 'Carrelage']);
        $tankpe = Zone::firstOrCreate(['nom' => 'Tankpè']);

        $client = User::factory()->create([
            'name' => 'Amina (Cliente test)',
            'estClient' => true,
            'estPrestataire' => false,
        ]);

        $prestataireUser = User::factory()->create([
            'name' => 'Alain K. (Carreleur test)',
            'estClient' => true,
            'estPrestataire' => true,
        ]);

        $providerProfile = ProviderProfile::create([
            'user_id' => $prestataireUser->id,
        ]);

        // 1. Le client publie une demande ouverte (Mode 2)
        $serviceRequest = ServiceRequest::create([
            'client_id' => $client->id,
            'service_category_id' => $carrelage->id,
            'zone_id' => $tankpe->id,
            'title' => 'Pose de carreaux dans mon salon',
            'description' => "Je souhaite poser du carrelage dans un salon d'environ 25 m².",
            'budget_estime' => 60000,
            'date_intervention' => now()->addWeek(),
            'status' => ServiceRequest::STATUS_PUBLISHED,
        ]);

        // 2. Le prestataire envoie un devis
        $proposal = Proposal::create([
            'service_request_id' => $serviceRequest->id,
            'provider_profile_id' => $providerProfile->id,
            'montant' => 55000,
            'delai' => '3 jours',
            'description' => 'Pose complète avec finitions soignées, matériel inclus.',
            'status' => Proposal::STATUS_PENDING,
        ]);

        $serviceRequest->update(['status' => ServiceRequest::STATUS_MATCHED]);

        $this->command->info("Scénario créé : ServiceRequest #{$serviceRequest->id}, Proposal #{$proposal->id}");
        $this->command->info("Client : {$client->email} | Prestataire : {$prestataireUser->email}");
        $this->command->info('Mot de passe par défaut (UserFactory) : password');
    }
}
