<?php
namespace Database\Seeders;

use App\Models\ProviderProfile;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use App\Models\Zone;
use Illuminate\Database\Seeder;

class ReferenceDataSeeder extends Seeder
{
    public function run(): void
    {
        $categoriesEtServices = [
            'Carrelage' => ['Pose de carrelage', 'Faïence murale', 'Réparation de carreaux'],
            'Plomberie' => ['Installation sanitaire', 'Réparation de fuite', 'Débouchage'],
            'Électricité' => ['Installation électrique', 'Dépannage', 'Mise aux normes'],
            'Peinture' => ['Peinture intérieure', 'Peinture extérieure'],
            'Menuiserie' => ['Fabrication de meubles', 'Pose de portes/fenêtres'],
        ];

        $services = collect();

        foreach ($categoriesEtServices as $categoryName => $serviceNames) {
            $category = ServiceCategory::firstOrCreate(['name' => $categoryName]);

            foreach ($serviceNames as $serviceName) {
                $services->push(
                    Service::firstOrCreate(['category_id' => $category->id, 'name' => $serviceName])
                );
            }
        }

        $zones = collect(['Tankpè', 'Calavi', 'Godomey', 'Cococodji', 'Cotonou'])
            ->map(fn ($name) => Zone::firstOrCreate(['name' => $name]));

        // Quelques prestataires de test, avec services + zones déclarés
        $providersData = [
            ['name' => 'Alain K. (Carreleur)', 'services' => ['Pose de carrelage', 'Faïence murale'], 'zones' => ['Tankpè', 'Calavi']],
            ['name' => 'Sophie M. (Électricienne)', 'services' => ['Installation électrique', 'Dépannage'], 'zones' => ['Tankpè', 'Cotonou']],
            ['name' => 'Jean D. (Plombier)', 'services' => ['Installation sanitaire', 'Réparation de fuite'], 'zones' => ['Godomey']],
        ];

        foreach ($providersData as $data) {
            $user = User::firstOrCreate(
                ['email' => \Illuminate\Support\Str::slug($data['name']).'@service229.test'],
                ['name' => $data['name'], 'password' => bcrypt('password'), 'estClient' => true, 'estPrestataire' => true]
            );

            $providerProfile = ProviderProfile::firstOrCreate(['user_id' => $user->id]);

            $serviceIds = $services->whereIn('name', $data['services'])->pluck('id');
            $providerProfile->services()->syncWithoutDetaching($serviceIds);

            $zoneIds = $zones->whereIn('name', $data['zones'])->pluck('id');
            $providerProfile->zones()->syncWithoutDetaching($zoneIds);
        }

        $this->command->info('Données de référence créées : 5 catégories, ~12 services, 5 zones, 3 prestataires.');
    }
}
