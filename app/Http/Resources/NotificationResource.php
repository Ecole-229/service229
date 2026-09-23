<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'message' => $this->message,
            'lien_associe' => $this->lien_associe,
            'lu' => $this->lu,
            'created_at' => $this->created_at,
        ];
    }
}
