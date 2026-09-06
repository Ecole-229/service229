<?php
namespace App\Listeners;

use App\Events\ProposalCreated;
use App\Models\Notification;

class NotifyClientOfNewProposal
{
    public function handle(ProposalCreated $event): void
    {
        $proposal = $event->proposal;
        $serviceRequest = $proposal->serviceRequest;

        Notification::create([
            'user_id' => $serviceRequest->client_id,
            'type' => Notification::TYPE_NOUVELLE_PROPOSAL,
            'message' => "Nouveau devis reçu pour « {$serviceRequest->title} »",
            'lien_associe' => "/service-requests/{$serviceRequest->id}",
        ]);
    }
}
