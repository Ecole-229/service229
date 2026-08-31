<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreServiceRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // tout utilisateur authentifié peut créer une demande
    }

    public function rules(): array
    {
        return [
            'service_category_id' => ['required', 'exists:service_categories,id'],
            'zone_id' => ['required', 'exists:zones,id'],
            'provider_profile_id' => ['nullable', 'exists:provider_profiles,id'],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'budget_estime' => ['nullable', 'numeric', 'min:0'],
            'date_intervention' => ['nullable', 'date', 'after_or_equal:today'],
            'photos' => ['nullable', 'array', 'max:5'],
            'photos.*' => ['image', 'mimes:jpg,jpeg,png', 'max:5120'], // 5 Mo, cohérent avec la maquette
        ];
    }
}
