<?php
namespace App\Http\Controllers;

use App\Http\Requests\StoreServiceRequestRequest;
use App\Models\ServiceRequest;
use App\Services\Marketplace\ServiceRequestService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ServiceRequestController extends Controller
{
    public function __construct(private ServiceRequestService $serviceRequestService)
    {
    }

    public function index(Request $request): Response
    {
        $serviceRequests = ServiceRequest::query()
            ->where('client_id', $request->user()->id)
            ->with(['serviceCategory', 'zone', 'providerProfile', 'proposals'])
            ->latest()
            ->paginate(10);

        return Inertia::render('ServiceRequests/Index', [
            'serviceRequests' => $serviceRequests,
        ]);
    }

    public function create(Request $request): Response
    {
        return Inertia::render('ServiceRequests/Create', [
            'serviceCategories' => \App\Models\ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => \App\Models\Zone::orderBy('name')->get(['id', 'name']),
            'preselectedProviderProfileId' => $request->integer('provider_profile_id') ?: null,
        ]);
    }

    public function show(Request $request, ServiceRequest $serviceRequest): Response
    {
        $this->authorize('view', $serviceRequest);

        $serviceRequest->load([
            'serviceCategory',
            'zone',
            'providerProfile',
            'proposals.providerProfile.user',
            'mission',
            'conversation.messages',
            'photos',
        ]);

        return Inertia::render('ServiceRequests/Show', [
            'serviceRequest' => $serviceRequest,
        ]);
    }

    public function store(StoreServiceRequestRequest $request): RedirectResponse
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

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', 'Demande créée avec succès.');
    }

    public function edit(Request $request, ServiceRequest $serviceRequest): Response
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être modifié.');

        $serviceRequest->load('photos');

        return Inertia::render('ServiceRequests/Edit', [
            'serviceRequest' => $serviceRequest,
            'serviceCategories' => \App\Models\ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => \App\Models\Zone::orderBy('name')->get(['id', 'name']),
        ]);
    }

    public function update(StoreServiceRequestRequest $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être modifié.');

        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $this->serviceRequestService->update(
            $serviceRequest,
            $validated,
            $photos,
            $request->boolean('as_draft')
        );

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', $request->boolean('as_draft') ? 'Brouillon mis à jour.' : 'Demande publiée.');
    }

    public function destroy(Request $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être supprimé.');

        $this->serviceRequestService->delete($serviceRequest);

        return redirect()
            ->route('service-requests.index')
            ->with('success', 'Brouillon supprimé.');
    }

    public function cancel(Request $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        $this->authorize('cancel', $serviceRequest);

        $this->serviceRequestService->cancel($serviceRequest);

        return redirect()
            ->route('service-requests.index')
            ->with('success', 'Demande annulée.');
    }

    public function browse(Request $request): Response
    {
        $user = $request->user();
        abort_unless($user->estPrestataire, 403, 'Cette page est réservée aux prestataires.');

        $serviceRequests = app(\App\Services\Marketplace\SearchService::class)
            ->availableRequestsForProvider($user);

        return Inertia::render('ServiceRequests/Browse', [
            'serviceRequests' => $serviceRequests,
        ]);
    }
}
