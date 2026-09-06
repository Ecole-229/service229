<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ServiceRequestPhoto extends Model
{
    protected $fillable = [
        'service_request_id',
        'chemin_fichier',
    ];

    public function serviceRequest(): BelongsTo
    {
        return $this->belongsTo(ServiceRequest::class);
    }

    // URL publique complète, utile côté Vue (ex: <img :src="photo.url">)
    public function getUrlAttribute(): string
    {
        return \Storage::disk('public')->url($this->chemin_fichier);
    }
}
