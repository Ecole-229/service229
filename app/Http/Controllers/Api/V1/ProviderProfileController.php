<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProviderProfileResource;
use App\Models\ProviderProfile;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class ProviderProfileController extends Controller
{
    use ApiResponse;

    private function currentProfile(Request $request): ProviderProfile
    {
        return ProviderProfile::query()
            ->where("user_id", $request->user()->id)
            ->firstOrFail();
    }

    private function loadSafeRelations(ProviderProfile $profile): ProviderProfile
    {
        $relations = array_values(array_filter(
            ["user", "services", "zones"],
            fn (string $relation) => method_exists(ProviderProfile::class, $relation)
        ));

        return $profile->load($relations);
    }

    public function show(Request $request)
    {
        $profile = $this->loadSafeRelations($this->currentProfile($request));

        return $this->success(
            (new ProviderProfileResource($profile))->resolve(),
            "Profil prestataire récupéré avec succès."
        );
    }

    public function syncServices(Request $request)
    {
        $validated = $request->validate([
            "service_ids" => ["required", "array"],
            "service_ids.*" => ["integer", "distinct", "exists:services,id"],
        ]);

        $profile = $this->currentProfile($request);

        if (! method_exists($profile, "services")) {
            return $this->error(
                "La relation ProviderProfile::services() doit être définie avant cette opération.",
                409
            );
        }

        $profile->services()->sync($validated["service_ids"]);

        return $this->success(
            (new ProviderProfileResource($this->loadSafeRelations($profile)))->resolve(),
            "Services du prestataire mis à jour."
        );
    }

    public function syncZones(Request $request)
    {
        $validated = $request->validate([
            "zone_ids" => ["required", "array"],
            "zone_ids.*" => ["integer", "distinct", "exists:zones,id"],
        ]);

        $profile = $this->currentProfile($request);

        if (! method_exists($profile, "zones")) {
            return $this->error(
                "La relation ProviderProfile::zones() doit être définie avant cette opération.",
                409
            );
        }

        $profile->zones()->sync($validated["zone_ids"]);

        return $this->success(
            (new ProviderProfileResource($this->loadSafeRelations($profile)))->resolve(),
            "Zones du prestataire mises à jour."
        );
    }
}
