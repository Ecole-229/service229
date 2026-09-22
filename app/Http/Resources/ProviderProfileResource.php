<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProviderProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            "id" => $this->id,
            "user_id" => $this->user_id,
            "user" => $this->whenLoaded("user", function () {
                return [
                    "id" => $this->user->id,
                    "name" => $this->user->name,
                ];
            }),
            "services" => ServiceResource::collection($this->whenLoaded("services")),
            "zones" => ZoneResource::collection($this->whenLoaded("zones")),
        ];
    }
}
