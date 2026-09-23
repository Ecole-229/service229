<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'client' => $this->whenLoaded('client', fn () => [
                'id' => $this->client->id,
                'name' => $this->client->name,
            ]),
            'provider_profile' => $this->whenLoaded('providerProfile', fn () => [
                'id' => $this->providerProfile->id,
                'name' => $this->providerProfile->user?->name,
            ]),
            'service_request' => $this->whenLoaded('serviceRequest', fn () => $this->serviceRequest ? [
                'id' => $this->serviceRequest->id,
                'title' => $this->serviceRequest->title,
            ] : null),
            'unread_count' => $this->whenCounted('unread_count', $this->unread_count ?? null),
            'messages' => MessageResource::collection($this->whenLoaded('messages')),
            'updated_at' => $this->updated_at,
        ];
    }
}
