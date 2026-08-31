<?php
namespace App\Http\Controllers;

use App\Http\Requests\StoreServiceRequestRequest;
use App\Models\ServiceRequest;
use App\Models\ServiceRequestPhoto;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;

class ServiceRequestController extends Controller
{
    /**
     * Liste des demandes du client connecté (son "espace demandes").
     */
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

    /**
     * Détail d'une demande (devis reçus, conversation, statut...).
     */
    public function show(Request $request, ServiceRequest $serviceRequest): Response
    {
        $this->authorize('view', $serviceRequest);

        $serviceRequest->load([
            'serviceCategory',
            'zone',
            'providerProfile',
            'proposals.providerProfile',
            'mission',
            'conversation.messages',
            'photos',
        ]);

        return Inertia::render('ServiceRequests/Show', [
            'serviceRequest' => $serviceRequest,
        ]);
    }

    /**
     * Création d'une demande — couvre les deux modes (section 2.2 du document) :
     * - Mode 1 : contact direct (provider_profile_id renseigné) -> statut "assigned" direct
     * - Mode 2 : besoin ouvert (provider_profile_id absent) -> statut "published"
     */
    public function store(StoreServiceRequestRequest $request): RedirectResponse
    {
        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $isDirectContact = ! empty($validated['provider_profile_id']);

        // "Enregistrer en brouillon" vs "Publier ma demande" (deux boutons de la maquette)
        $status = match (true) {
            $isDirectContact => ServiceRequest::STATUS_ASSIGNED,
            $request->boolean('as_draft') => ServiceRequest::STATUS_DRAFT,
            default => ServiceRequest::STATUS_PUBLISHED,
        };

        $serviceRequest = ServiceRequest::create([
            ...$validated,
            'client_id' => $request->user()->id,
            'status' => $status,
        ]);

        foreach ($photos as $photo) {
            $path = $photo->store('service-requests', 'public');

            ServiceRequestPhoto::create([
                'service_request_id' => $serviceRequest->id,
                'chemin_fichier' => $path,
            ]);
        }

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', 'Demande créée avec succès.');
    }

    /**
     * Annulation d'une demande par le client — uniquement si elle n'est pas
     * déjà engagée sur une mission (status assigned/matched restent annulables,
     * mais pas une demande déjà "closed").
     */
    public function cancel(Request $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        $this->authorize('cancel', $serviceRequest);

        $serviceRequest->update(['status' => ServiceRequest::STATUS_CANCELLED]);

        return redirect()
            ->route('service-requests.index')
            ->with('success', 'Demande annulée.');
    }
}
