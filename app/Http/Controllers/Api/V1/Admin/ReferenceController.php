<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceCategoryResource;
use App\Http\Resources\ServiceResource;
use App\Http\Resources\ZoneResource;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\Zone;
use App\Support\ApiResponse;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;

class ReferenceController extends Controller
{
    use ApiResponse;

    public function storeCategory(Request $request)
    {
        $validated = $request->validate([
            "name" => ["required", "string", "max:255", "unique:service_categories,name"],
        ]);

        $category = ServiceCategory::create($validated);

        return $this->success(
            (new ServiceCategoryResource($category))->resolve(),
            "Catégorie créée.",
            201
        );
    }

    public function updateCategory(Request $request, ServiceCategory $category)
    {
        $validated = $request->validate([
            "name" => [
                "required", "string", "max:255",
                "unique:service_categories,name,".$category->id,
            ],
        ]);

        $category->update($validated);

        return $this->success(
            (new ServiceCategoryResource($category))->resolve(),
            "Catégorie mise à jour."
        );
    }

    public function destroyCategory(ServiceCategory $category)
    {
        try {
            $category->delete();
        } catch (QueryException $e) {
            return $this->error(
                "Impossible de supprimer cette catégorie car elle est encore utilisée.",
                409
            );
        }

        return $this->success(null, "Catégorie supprimée.");
    }

    public function storeService(Request $request)
    {
        $validated = $request->validate([
            "category_id" => ["required", "integer", "exists:service_categories,id"],
            "name" => ["required", "string", "max:255"],
        ]);

        $service = Service::create($validated);

        return $this->success(
            (new ServiceResource($service->load("category")))->resolve(),
            "Service créé.",
            201
        );
    }

    public function updateService(Request $request, Service $service)
    {
        $validated = $request->validate([
            "category_id" => ["required", "integer", "exists:service_categories,id"],
            "name" => ["required", "string", "max:255"],
        ]);

        $service->update($validated);

        return $this->success(
            (new ServiceResource($service->load("category")))->resolve(),
            "Service mis à jour."
        );
    }

    public function destroyService(Service $service)
    {
        try {
            $service->delete();
        } catch (QueryException $e) {
            return $this->error(
                "Impossible de supprimer ce service car il est encore utilisé.",
                409
            );
        }

        return $this->success(null, "Service supprimé.");
    }

    public function storeZone(Request $request)
    {
        $validated = $request->validate([
            "name" => ["required", "string", "max:255", "unique:zones,name"],
        ]);

        $zone = Zone::create($validated);

        return $this->success(
            (new ZoneResource($zone))->resolve(),
            "Zone créée.",
            201
        );
    }

    public function updateZone(Request $request, Zone $zone)
    {
        $validated = $request->validate([
            "name" => [
                "required", "string", "max:255",
                "unique:zones,name,".$zone->id,
            ],
        ]);

        $zone->update($validated);

        return $this->success(
            (new ZoneResource($zone))->resolve(),
            "Zone mise à jour."
        );
    }

    public function destroyZone(Zone $zone)
    {
        try {
            $zone->delete();
        } catch (QueryException $e) {
            return $this->error(
                "Impossible de supprimer cette zone car elle est encore utilisée.",
                409
            );
        }

        return $this->success(null, "Zone supprimée.");
    }
}
