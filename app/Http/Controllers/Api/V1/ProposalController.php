<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreProposalRequest;
use App\Http\Resources\MissionResource;
use App\Http\Resources\ProposalResource;
use App\Models\Proposal;
use App\Models\ProviderProfile;
use App\Models\ServiceRequest;
use App\Services\Marketplace\ProposalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProposalController extends Controller
{
    public function __construct(private ProposalService $proposalService)
    {
    }

    public function index(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->authorize('view', $serviceRequest);

        return response()->json([
            'data' => ProposalResource::collection(
                $serviceRequest->proposals()->with('providerProfile.user')->get()
            ),
        ]);
    }

    public function store(StoreProposalRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $providerProfile = ProviderProfile::where('user_id', $request->user()->id)->first();
        abort_unless($providerProfile, 422, "Vous n'avez pas encore de profil prestataire.");

        $proposal = $this->proposalService->submit($serviceRequest, $providerProfile, $request->validated());

        return response()->json(['data' => new ProposalResource($proposal)], 201);
    }

    public function accept(Request $request, Proposal $proposal): JsonResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $mission = $this->proposalService->accept($proposal);

        return response()->json(['data' => new MissionResource($mission)]);
    }

    public function reject(Request $request, Proposal $proposal): JsonResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $this->proposalService->reject($proposal);

        return response()->json(['data' => new ProposalResource($proposal->fresh())]);
    }

    public function withdraw(Request $request, Proposal $proposal): JsonResponse
    {
        $this->authorize('withdraw', $proposal);

        $this->proposalService->withdraw($proposal);

        return response()->json(['data' => new ProposalResource($proposal->fresh())]);
    }
}
