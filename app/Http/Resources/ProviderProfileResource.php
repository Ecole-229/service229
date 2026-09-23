<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProviderProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->user?->name,
            'services' => $this->whenLoaded('services', fn () => $this->services->map(fn ($s) => [
                'id' => $s->id,
                'name' => $s->name,
            ])),
            'zones' => $this->whenLoaded('zones', fn () => $this->zones->map(fn ($z) => [
                'id' => $z->id,
                'name' => $z->name,
            ])),
        ];
    }
}
