<?php
namespace App\Http\Controllers;

use App\Models\ServiceCategory;
use App\Models\Zone;
use App\Services\Marketplace\SearchService;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class SearchController extends Controller
{
    public function __construct(private SearchService $searchService)
    {
    }

    public function home(): Response
    {
        return Inertia::render('Home', [
            'serviceCategories' => ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => Zone::orderBy('name')->get(['id', 'name']),
        ]);
    }

    public function index(Request $request): Response
    {
        $validated = $request->validate([
            'service_category_id' => ['nullable', 'exists:service_categories,id'],
            'zone_id' => ['nullable', 'exists:zones,id'],
        ]);

        $providers = $this->searchService->searchProviders(
            $validated['service_category_id'] ?? null,
            $validated['zone_id'] ?? null,
        );

        return Inertia::render('Search/Results', [
            'providers' => $providers,
            'filters' => $validated,
            'serviceCategories' => ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => Zone::orderBy('name')->get(['id', 'name']),
        ]);
    }
}
