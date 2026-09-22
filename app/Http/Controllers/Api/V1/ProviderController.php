<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProviderProfileResource;
use App\Models\ProviderProfile;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class ProviderController extends Controller
{
    use ApiResponse;

    private function relations(): array
    {
        return array_values(array_filter(
            ["user", "services", "zones"],
            fn (string $relation) => method_exists(ProviderProfile::class, $relation)
        ));
    }

    public function index(Request $request)
    {
        $query = ProviderProfile::query()->with($this->relations());

        if ($request->filled("service_id") && method_exists(ProviderProfile::class, "services")) {
            $serviceId = $request->integer("service_id");
            $query->whereHas("services", fn ($q) => $q->where("services.id", $serviceId));
        }

        if ($request->filled("zone_id") && method_exists(ProviderProfile::class, "zones")) {
            $zoneId = $request->integer("zone_id");
            $query->whereHas("zones", fn ($q) => $q->where("zones.id", $zoneId));
        }

        $providers = $query->paginate(15);

        return $this->paginated(
            $providers,
            ProviderProfileResource::collection($providers->getCollection())->resolve(),
            "Prestataires récupérés avec succès."
        );
    }

    public function show(ProviderProfile $provider)
    {
        $provider->load($this->relations());

        return $this->success(
            (new ProviderProfileResource($provider))->resolve(),
            "Prestataire récupéré avec succès."
        );
    }
}
