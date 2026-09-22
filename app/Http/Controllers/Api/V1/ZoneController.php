<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ZoneResource;
use App\Models\Zone;
use App\Support\ApiResponse;

class ZoneController extends Controller
{
    use ApiResponse;

    public function index()
    {
        return $this->success(
            ZoneResource::collection(Zone::query()->orderBy("name")->get())->resolve(),
            "Zones récupérées avec succès."
        );
    }

    public function show(Zone $zone)
    {
        return $this->success(
            (new ZoneResource($zone))->resolve(),
            "Zone récupérée avec succès."
        );
    }
}
