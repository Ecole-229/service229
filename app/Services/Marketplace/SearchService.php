<?php
namespace App\Services\Marketplace;

use App\Models\ProviderProfile;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

class SearchService
{
    /**
     * Recherche publique de prestataires par catégorie + zone.
     * Utilisé par SearchController (Inertia) et Api\V1\SearchController.
     */
    public function searchProviders(?int $serviceCategoryId, ?int $zoneId): Collection
    {
        return ProviderProfile::query()
            ->with(['user', 'services.category', 'zones'])
            ->when(
                $serviceCategoryId,
                fn ($q, $categoryId) => $q->whereHas(
                    'services',
                    fn ($sq) => $sq->where('category_id', $categoryId)
                )
            )
            ->when(
                $zoneId,
                fn ($q, $zoneId) => $q->whereHas('zones', fn ($zq) => $zq->where('zones.id', $zoneId))
            )
            ->get();
    }

    /**
     * "Demandes disponibles" pour un prestataire : demandes publiées qui
     * correspondent à ses services/zones déclarés, hors celles où il a
     * déjà répondu.
     */
    public function availableRequestsForProvider(User $user): LengthAwarePaginator
    {
        $providerProfile = ProviderProfile::where('user_id', $user->id)->first();

        $serviceIds = $providerProfile?->services()->pluck('services.id') ?? collect();
        $zoneIds = $providerProfile?->zones()->pluck('zones.id') ?? collect();

        return ServiceRequest::query()
            ->where('status', ServiceRequest::STATUS_PUBLISHED)
            ->when($serviceIds->isNotEmpty(), function ($q) use ($serviceIds) {
                $q->whereHas(
                    'serviceCategory.services',
                    fn ($sq) => $sq->whereIn('services.id', $serviceIds)
                );
            })
            ->when($zoneIds->isNotEmpty(), fn ($q) => $q->whereIn('zone_id', $zoneIds))
            ->whereDoesntHave(
                'proposals',
                fn ($q) => $q->where('provider_profile_id', $providerProfile?->id)
            )
            ->with(['serviceCategory', 'zone', 'client'])
            ->latest()
            ->paginate(10);
    }
}
