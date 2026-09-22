<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            "id" => $this->id,
            "category_id" => $this->category_id,
            "name" => $this->name,
            "category" => new ServiceCategoryResource($this->whenLoaded("category")),
        ];
    }
}
