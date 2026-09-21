<?php
namespace App\Services\Marketplace;

use App\Events\ProposalAccepted;
use App\Events\ProposalCreated;
use App\Models\Mission;
use App\Models\Proposal;
use App\Models\ProviderProfile;
use App\Models\ServiceRequest;
use Illuminate\Support\Facades\DB;

class ProposalService
{
    public function submit(ServiceRequest $serviceRequest, ProviderProfile $providerProfile, array $data): Proposal
    {
        abort_unless($serviceRequest->isOpenToProposals(), 422, "Cette demande n'accepte plus de devis.");

        $proposal = Proposal::create([
            ...$data,
            'service_request_id' => $serviceRequest->id,
            'provider_profile_id' => $providerProfile->id,
            'status' => Proposal::STATUS_PENDING,
        ]);

        if ($serviceRequest->status === ServiceRequest::STATUS_PUBLISHED) {
            $serviceRequest->update(['status' => ServiceRequest::STATUS_MATCHED]);
        }

        ProposalCreated::dispatch($proposal);

        return $proposal;
    }

    /**
     * Accepte un devis : rejette automatiquement les autres pending,
     * passe la demande à "assigned", crée la Mission — le tout en
     * transaction pour ne jamais laisser un état intermédiaire incohérent.
     */
    public function accept(Proposal $proposal): Mission
    {
        abort_unless($proposal->status === Proposal::STATUS_PENDING, 422, "Ce devis n'est plus disponible.");

        $serviceRequest = $proposal->serviceRequest;
        $mission = null;

        DB::transaction(function () use ($proposal, $serviceRequest, &$mission) {
            $proposal->update(['status' => Proposal::STATUS_ACCEPTED]);

            $serviceRequest->proposals()
                ->where('id', '!=', $proposal->id)
                ->where('status', Proposal::STATUS_PENDING)
                ->update(['status' => Proposal::STATUS_REJECTED]);

            $serviceRequest->update(['status' => ServiceRequest::STATUS_ASSIGNED]);

            $mission = Mission::create([
                'service_request_id' => $serviceRequest->id,
                'proposal_id' => $proposal->id,
                'client_id' => $serviceRequest->client_id,
                'provider_profile_id' => $proposal->provider_profile_id,
                'status' => Mission::STATUS_PENDING,
                'paiementEffectue' => false,
            ]);
        });

        ProposalAccepted::dispatch($proposal->fresh());

        return $mission;
    }

    public function reject(Proposal $proposal): void
    {
        abort_unless($proposal->status === Proposal::STATUS_PENDING, 422, "Ce devis n'est plus disponible.");

        $proposal->update(['status' => Proposal::STATUS_REJECTED]);
    }

    public function withdraw(Proposal $proposal): void
    {
        abort_unless($proposal->status === Proposal::STATUS_PENDING, 422, "Ce devis n'est plus disponible.");

        $proposal->update(['status' => Proposal::STATUS_WITHDRAWN]);
    }
}
