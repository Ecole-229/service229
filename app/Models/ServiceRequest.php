<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ServiceRequest extends Model
{
    // Statuts figés — section 4.1 du document de référence
    public const STATUS_DRAFT = 'draft';
    public const STATUS_PUBLISHED = 'published';
    public const STATUS_MATCHED = 'matched';
    public const STATUS_ASSIGNED = 'assigned';
    public const STATUS_CANCELLED = 'cancelled';
    public const STATUS_EXPIRED = 'expired';
    public const STATUS_CLOSED = 'closed';

    protected $fillable = [
        'client_id',
        'service_category_id',
        'zone_id',
        'provider_profile_id',
        'title',
        'description',
        'budget_estime',
        'date_intervention',
        'status',
    ];

    protected $casts = [
        'budget_estime' => 'decimal:2',
        'date_intervention' => 'date',
    ];

    // --- Relations ---

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function serviceCategory(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class);
    }

    public function zone(): BelongsTo
    {
        return $this->belongsTo(Zone::class);
    }

    // Renseigné uniquement en Mode 1 (contact direct)
    public function providerProfile(): BelongsTo
    {
        return $this->belongsTo(ProviderProfile::class);
    }

    public function proposals(): HasMany
    {
        return $this->hasMany(Proposal::class);
    }

    public function mission(): HasOne
    {
        return $this->hasOne(Mission::class);
    }

    public function conversation(): HasOne
    {
        return $this->hasOne(Conversation::class);
    }

    public function photos(): HasMany
    {
        return $this->hasMany(ServiceRequestPhoto::class);
    }

    // --- Helpers ---

    public function isOpenToProposals(): bool
    {
        return $this->status === self::STATUS_PUBLISHED;
    }
}
