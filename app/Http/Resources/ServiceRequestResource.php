<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status,
            'budget_estime' => $this->budget_estime,
            'date_intervention' => $this->date_intervention,
            'client_id' => $this->client_id,
            'service_category' => $this->whenLoaded('serviceCategory', fn () => [
                'id' => $this->serviceCategory->id,
                'name' => $this->serviceCategory->name,
            ]),
            'zone' => $this->whenLoaded('zone', fn () => [
                'id' => $this->zone->id,
                'name' => $this->zone->name,
            ]),
            'photos' => $this->whenLoaded('photos', fn () => $this->photos->map(fn ($p) => [
                'id' => $p->id,
                'url' => $p->url,
            ])),
            'proposals' => ProposalResource::collection($this->whenLoaded('proposals')),
            'proposals_count' => $this->whenCounted('proposals'),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
