<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MissionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
            'paiementEffectue' => $this->paiementEffectue,
            'service_request' => $this->whenLoaded('serviceRequest', fn () => [
                'id' => $this->serviceRequest->id,
                'title' => $this->serviceRequest->title,
            ]),
            'client' => $this->whenLoaded('client', fn () => [
                'id' => $this->client->id,
                'name' => $this->client->name,
            ]),
            'provider_profile' => $this->whenLoaded('providerProfile', fn () => [
                'id' => $this->providerProfile->id,
                'name' => $this->providerProfile->user?->name,
            ]),
            'review' => new ReviewResource($this->whenLoaded('review')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
