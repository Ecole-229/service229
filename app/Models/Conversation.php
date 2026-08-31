<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Conversation extends Model
{
    protected $fillable = [
        'service_request_id',
        'client_id',
        'provider_profile_id',
    ];

    // --- Relations ---

    // Nullable : référence la demande actuellement en cours de discussion,
    // le fil reste unique par duo client/prestataire (voir migration)
    public function serviceRequest(): BelongsTo
    {
        return $this->belongsTo(ServiceRequest::class);
    }

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function providerProfile(): BelongsTo
    {
        return $this->belongsTo(ProviderProfile::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }
}
