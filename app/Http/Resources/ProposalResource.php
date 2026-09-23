<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProposalResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'montant' => $this->montant,
            'delai' => $this->delai,
            'description' => $this->description,
            'status' => $this->status,
            'service_request_id' => $this->service_request_id,
            'provider_profile' => $this->whenLoaded('providerProfile', fn () => [
                'id' => $this->providerProfile->id,
                'name' => $this->providerProfile->user?->name,
            ]),
            'created_at' => $this->created_at,
        ];
    }
}
