<?php
namespace App\Services\Marketplace;

use App\Events\MissionCompleted;
use App\Models\Mission;
use App\Models\ServiceRequest;

class MissionService
{
    public function start(Mission $mission): void
    {
        abort_unless($mission->status === Mission::STATUS_PENDING, 422, 'Cette mission ne peut pas démarrer.');

        $mission->update(['status' => Mission::STATUS_IN_PROGRESS]);
    }

    public function markAwaitingConfirmation(Mission $mission): void
    {
        abort_unless($mission->status === Mission::STATUS_IN_PROGRESS, 422, "Cette mission n'est pas en cours.");

        $mission->update(['status' => Mission::STATUS_AWAITING_CONFIRMATION]);
    }

    public function confirmCompletion(Mission $mission): void
    {
        abort_unless($mission->status === Mission::STATUS_AWAITING_CONFIRMATION, 422, 'Rien à confirmer pour le moment.');

        $mission->update(['status' => Mission::STATUS_COMPLETED]);
        $mission->serviceRequest->update(['status' => ServiceRequest::STATUS_CLOSED]);

        MissionCompleted::dispatch($mission->fresh());
    }

    public function markPaid(Mission $mission): void
    {
        $mission->update(['paiementEffectue' => true]);
    }

    public function cancel(Mission $mission): void
    {
        abort_if(
            in_array($mission->status, [Mission::STATUS_COMPLETED, Mission::STATUS_CANCELLED]),
            422,
            'Cette mission ne peut plus être annulée.'
        );

        $mission->update(['status' => Mission::STATUS_CANCELLED]);
    }

    /**
     * Statut "disputed" — prévu par le document/prompt mais jamais câblé
     * côté UI jusqu'ici (endpoint API l'exige explicitement : POST .../dispute).
     */
    public function dispute(Mission $mission): void
    {
        abort_if(
            in_array($mission->status, [Mission::STATUS_COMPLETED, Mission::STATUS_CANCELLED]),
            422,
            'Cette mission ne peut plus être contestée.'
        );

        $mission->update(['status' => Mission::STATUS_DISPUTED]);
    }
}
