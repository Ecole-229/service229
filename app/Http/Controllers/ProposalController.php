<?php
namespace App\Http\Controllers;

use App\Events\ProposalAccepted as ProposalAcceptedEvent;
use App\Events\ProposalCreated;
use App\Http\Requests\StoreProposalRequest;
use App\Models\Mission;
use App\Models\Proposal;
use App\Models\ServiceRequest;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class ProposalController extends Controller
{
    /**
     * Un prestataire envoie un devis sur une demande ouverte (Mode 2).
     * Passe la ServiceRequest de "published" à "matched" au premier devis reçu.
     */
    public function store(StoreProposalRequest $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        abort_unless($serviceRequest->isOpenToProposals(), 422, 'Cette demande n\'accepte plus de devis.');

        $validated = $request->validated();

        $providerProfile = \App\Models\ProviderProfile::where('user_id', $request->user()->id)->first();
        abort_unless($providerProfile, 422, "Vous n'avez pas encore de profil prestataire.");
        $providerProfileId = $providerProfile->id;

        $proposal = Proposal::create([
            ...$validated,
            'service_request_id' => $serviceRequest->id,
            'provider_profile_id' => $providerProfileId,
            'status' => Proposal::STATUS_PENDING,
        ]);

        if ($serviceRequest->status === ServiceRequest::STATUS_PUBLISHED) {
            $serviceRequest->update(['status' => ServiceRequest::STATUS_MATCHED]);
        }

        ProposalCreated::dispatch($proposal);

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', 'Devis envoyé.');
    }

    /**
     * Le client accepte un devis : le devis passe à "accepted", tous les
     * autres devis pending de la même demande sont automatiquement "rejected",
     * la demande passe à "assigned", et une Mission est créée.
     */
    public function accept(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $serviceRequest = $proposal->serviceRequest;
        $mission = null;

        \DB::transaction(function () use ($proposal, $serviceRequest, &$mission) {
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

        ProposalAcceptedEvent::dispatch($proposal->fresh());

        return redirect()
            ->route('missions.show', $mission)
            ->with('success', 'Devis accepté, mission créée.');
    }

    /**
     * Le client refuse un devis précis (sans accepter les autres pour autant).
     */
    public function reject(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $proposal->update(['status' => Proposal::STATUS_REJECTED]);

        return back()->with('success', 'Devis refusé.');
    }

    /**
     * Le prestataire retire lui-même son devis.
     */
    public function withdraw(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('withdraw', $proposal);

        $proposal->update(['status' => Proposal::STATUS_WITHDRAWN]);

        return back()->with('success', 'Devis retiré.');
    }
}
