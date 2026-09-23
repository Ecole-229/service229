<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProviderProfileResource;
use App\Services\Marketplace\SearchService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function __construct(private SearchService $searchService)
    {
    }

    public function providers(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'service_category_id' => ['nullable', 'integer', 'exists:service_categories,id'],
            'zone_id' => ['nullable', 'integer', 'exists:zones,id'],
        ]);

        $providers = $this->searchService->searchProviders(
            $validated['service_category_id'] ?? null,
            $validated['zone_id'] ?? null,
        );

        return response()->json([
            'data' => ProviderProfileResource::collection($providers),
        ]);
    }
}
