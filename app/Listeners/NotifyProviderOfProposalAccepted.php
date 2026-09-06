<?php
namespace App\Listeners;

use App\Events\ProposalAccepted;
use App\Models\Notification;

class NotifyProviderOfProposalAccepted
{
    public function handle(ProposalAccepted $event): void
    {
        $proposal = $event->proposal;
        $providerUserId = $proposal->providerProfile->user_id;

        Notification::create([
            'user_id' => $providerUserId,
            'type' => Notification::TYPE_PROPOSAL_ACCEPTEE,
            'message' => "Votre devis a été accepté pour « {$proposal->serviceRequest->title} »",
            'lien_associe' => "/missions/{$proposal->mission->id}",
        ]);
    }
}
