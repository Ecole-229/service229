<?php
namespace App\Http\Controllers;

use App\Http\Requests\StoreProposalRequest;
use App\Models\Proposal;
use App\Models\ProviderProfile;
use App\Models\ServiceRequest;
use App\Services\Marketplace\ProposalService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class ProposalController extends Controller
{
    public function __construct(private ProposalService $proposalService)
    {
    }

    public function store(StoreProposalRequest $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        $providerProfile = ProviderProfile::where('user_id', $request->user()->id)->first();
        abort_unless($providerProfile, 422, "Vous n'avez pas encore de profil prestataire.");

        $this->proposalService->submit($serviceRequest, $providerProfile, $request->validated());

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', 'Devis envoyé.');
    }

    public function accept(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $mission = $this->proposalService->accept($proposal);

        return redirect()
            ->route('missions.show', $mission)
            ->with('success', 'Devis accepté, mission créée.');
    }

    public function reject(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $this->proposalService->reject($proposal);

        return back()->with('success', 'Devis refusé.');
    }

    public function withdraw(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('withdraw', $proposal);

        $this->proposalService->withdraw($proposal);

        return back()->with('success', 'Devis retiré.');
    }
}
