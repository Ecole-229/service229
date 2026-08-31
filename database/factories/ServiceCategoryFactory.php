<?php
namespace Database\Factories;

use App\Models\ServiceCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

class ServiceCategoryFactory extends Factory
{
    protected $model = ServiceCategory::class;

    public function definition(): array
    {
        return [
            'nom' => fake()->randomElement([
                'Carrelage', 'Plomberie', 'Électricité', 'Peinture', 'Menuiserie',
            ]),
        ];
    }
}
