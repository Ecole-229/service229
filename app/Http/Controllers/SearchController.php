<?php
namespace App\Http\Controllers;

use App\Models\ProviderProfile;
use App\Models\ServiceCategory;
use App\Models\Zone;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class SearchController extends Controller
{
    /**
     * Page d'accueil publique (correspond à l'écran "Trouvez le bon
     * professionnel" de la maquette).
     */
    public function home(): Response
    {
        return Inertia::render('Home', [
            'serviceCategories' => ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => Zone::orderBy('name')->get(['id', 'name']),
        ]);
    }

    /**
     * Résultats de recherche par catégorie + zone (correspond à l'écran
     * "Carreleurs disponibles à Tankpè" de la maquette).
     */
    public function index(Request $request): Response
    {
        $validated = $request->validate([
            'service_category_id' => ['nullable', 'exists:service_categories,id'],
            'zone_id' => ['nullable', 'exists:zones,id'],
        ]);

        $providers = ProviderProfile::query()
            ->with(['user', 'services.category', 'zones'])
            ->when(
                $validated['service_category_id'] ?? null,
                fn ($q, $categoryId) => $q->whereHas(
                    'services',
                    fn ($sq) => $sq->where('category_id', $categoryId)
                )
            )
            ->when(
                $validated['zone_id'] ?? null,
                fn ($q, $zoneId) => $q->whereHas('zones', fn ($zq) => $zq->where('zones.id', $zoneId))
            )
            ->get();

        return Inertia::render('Search/Results', [
            'providers' => $providers,
            'filters' => $validated,
            'serviceCategories' => ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => Zone::orderBy('name')->get(['id', 'name']),
        ]);
    }
}
