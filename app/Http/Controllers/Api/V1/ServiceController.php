<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceResource;
use App\Models\Service;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class ServiceController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $query = Service::query()->orderBy("name");

        if (method_exists(Service::class, "category")) {
            $query->with("category");
        }

        $query->when(
            $request->filled("category_id"),
            fn ($q) => $q->where("category_id", $request->integer("category_id"))
        );

        $query->when(
            $request->filled("q"),
            fn ($q) => $q->where("name", "like", "%".$request->string("q")."%")
        );

        return $this->success(
            ServiceResource::collection($query->get())->resolve(),
            "Services récupérés avec succès."
        );
    }

    public function show(Service $service)
    {
        if (method_exists($service, "category")) {
            $service->load("category");
        }

        return $this->success(
            (new ServiceResource($service))->resolve(),
            "Service récupéré avec succès."
        );
    }
}
