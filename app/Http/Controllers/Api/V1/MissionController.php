<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\MissionResource;
use App\Models\Mission;
use App\Services\Marketplace\MissionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MissionController extends Controller
{
    public function __construct(private MissionService $missionService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $missions = Mission::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['serviceRequest', 'client', 'providerProfile.user', 'review'])
            ->latest()
            ->paginate(15);

        return response()->json([
            'data' => MissionResource::collection($missions),
            'meta' => [
                'current_page' => $missions->currentPage(),
                'last_page' => $missions->lastPage(),
                'total' => $missions->total(),
            ],
        ]);
    }

    public function show(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('view', $mission);

        $mission->load(['serviceRequest', 'client', 'providerProfile.user', 'review']);

        return response()->json(['data' => new MissionResource($mission)]);
    }

    public function start(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('start', $mission);

        $this->missionService->start($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }

    /**
     * Le prestataire signale que le travail est terminé.
     */
    public function finish(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('markAwaitingConfirmation', $mission);

        $this->missionService->markAwaitingConfirmation($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }

    /**
     * Le client confirme la fin des travaux.
     */
    public function confirm(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('confirmCompletion', $mission);

        $this->missionService->confirmCompletion($mission);

        return response()->json(['data' => new MissionResource($mission->fresh()->load('review'))]);
    }

    public function dispute(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('dispute', $mission);

        $this->missionService->dispute($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }

    // --- Endpoints supplémentaires (au-delà du minimum demandé) ---

    public function markPaid(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('markPaid', $mission);

        $this->missionService->markPaid($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }

    public function cancel(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('cancel', $mission);

        $this->missionService->cancel($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }
}
