<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreServiceRequestRequest;
use App\Http\Resources\ServiceRequestResource;
use App\Models\ServiceRequest;
use App\Services\Marketplace\ServiceRequestService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ServiceRequestController extends Controller
{
    public function __construct(private ServiceRequestService $serviceRequestService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $serviceRequests = ServiceRequest::query()
            ->where('client_id', $request->user()->id)
            ->with(['serviceCategory', 'zone', 'proposals'])
            ->withCount('proposals')
            ->latest()
            ->paginate(15);

        return response()->json([
            'data' => ServiceRequestResource::collection($serviceRequests),
            'meta' => [
                'current_page' => $serviceRequests->currentPage(),
                'last_page' => $serviceRequests->lastPage(),
                'total' => $serviceRequests->total(),
            ],
        ]);
    }

    public function store(StoreServiceRequestRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $serviceRequest = $this->serviceRequestService->create(
            $request->user(),
            $validated,
            $photos,
            $request->boolean('as_draft')
        );

        return response()->json([
            'data' => new ServiceRequestResource($serviceRequest->load(['serviceCategory', 'zone'])),
        ], 201);
    }

    public function show(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->authorize('view', $serviceRequest);

        $serviceRequest->load(['serviceCategory', 'zone', 'proposals.providerProfile.user', 'photos']);

        return response()->json([
            'data' => new ServiceRequestResource($serviceRequest),
        ]);
    }

    public function update(StoreServiceRequestRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être modifié.');

        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $serviceRequest = $this->serviceRequestService->update(
            $serviceRequest,
            $validated,
            $photos,
            $request->boolean('as_draft')
        );

        return response()->json([
            'data' => new ServiceRequestResource($serviceRequest->load(['serviceCategory', 'zone'])),
        ]);
    }
}
