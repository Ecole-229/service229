<?php
namespace Database\Factories;

use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

class ServiceFactory extends Factory
{
    protected $model = Service::class;

    public function definition(): array
    {
        return [
            'category_id' => ServiceCategory::factory(),
            'name' => fake()->randomElement([
                'Pose de carrelage', 'Faïence murale', 'Réparation de carreaux',
            ]),
        ];
    }
}
