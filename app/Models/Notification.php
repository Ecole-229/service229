<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notification extends Model
{
    // Types fermés et connus à l'avance — utilisés dans les Listeners
    public const TYPE_NOUVELLE_PROPOSAL = 'nouvelle_proposal';
    public const TYPE_PROPOSAL_ACCEPTEE = 'proposal_acceptee';
    public const TYPE_MISSION_TERMINEE = 'mission_terminee';
    public const TYPE_NOUVEAU_MESSAGE = 'nouveau_message';
    public const TYPE_NOUVEL_AVIS = 'nouvel_avis';

    protected $fillable = [
        'user_id',
        'type',
        'message',
        'lien_associe',
        'lu',
    ];

    protected $casts = [
        'lu' => 'boolean',
    ];

    // --- Relations ---

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
