<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceCategoryResource;
use App\Models\ServiceCategory;
use App\Support\ApiResponse;

class ServiceCategoryController extends Controller
{
    use ApiResponse;

    public function index()
    {
        $query = ServiceCategory::query()->orderBy("name");

        if (method_exists(ServiceCategory::class, "services")) {
            $query->with("services");
        }

        return $this->success(
            ServiceCategoryResource::collection($query->get())->resolve(),
            "Catégories récupérées avec succès."
        );
    }

    public function show(ServiceCategory $category)
    {
        if (method_exists($category, "services")) {
            $category->load("services");
        }

        return $this->success(
            (new ServiceCategoryResource($category))->resolve(),
            "Catégorie récupérée avec succès."
        );
    }
}
