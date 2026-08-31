<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Mission extends Model
{
    // Statuts figés — section 4.3 du document de référence
    public const STATUS_PENDING = 'pending';
    public const STATUS_IN_PROGRESS = 'in_progress';
    public const STATUS_AWAITING_CONFIRMATION = 'awaiting_confirmation';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_CANCELLED = 'cancelled';
    public const STATUS_DISPUTED = 'disputed';

    protected $fillable = [
        'service_request_id',
        'proposal_id',
        'client_id',
        'provider_profile_id',
        'status',
        'paiementEffectue',
    ];

    protected $casts = [
        'paiementEffectue' => 'boolean',
    ];

    // --- Relations ---

    public function serviceRequest(): BelongsTo
    {
        return $this->belongsTo(ServiceRequest::class);
    }

    public function proposal(): BelongsTo
    {
        return $this->belongsTo(Proposal::class);
    }

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function providerProfile(): BelongsTo
    {
        return $this->belongsTo(ProviderProfile::class);
    }

    public function review(): HasOne
    {
        return $this->hasOne(Review::class);
    }

    // --- Helpers ---

    public function isCompleted(): bool
    {
        return $this->status === self::STATUS_COMPLETED;
    }
}
