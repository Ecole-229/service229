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
            'proposals.providerProfile.user',
            'mission',
            'conversation.messages',
            'photos',
        ]);

        return Inertia::render('ServiceRequests/Show', [
            'serviceRequest' => $serviceRequest,
        ]);
    }

    /**
     * Affiche le formulaire de création (correspond à l'écran "Nouvelle
     * demande" de la maquette).
     */
    public function create(Request $request): Response
    {
        return Inertia::render('ServiceRequests/Create', [
            'serviceCategories' => \App\Models\ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => \App\Models\Zone::orderBy('name')->get(['id', 'name']),
            'preselectedProviderProfileId' => $request->integer('provider_profile_id') ?: null,
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

    /**
     * Formulaire pour continuer un brouillon (status = draft uniquement).
     */
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

    /**
     * Met à jour un brouillon — mêmes boutons "Publier"/"Enregistrer en
     * brouillon" que la création.
     */
    public function update(StoreServiceRequestRequest $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être modifié.');

        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $status = $request->boolean('as_draft') ? ServiceRequest::STATUS_DRAFT : ServiceRequest::STATUS_PUBLISHED;

        $serviceRequest->update([...$validated, 'status' => $status]);

        foreach ($photos as $photo) {
            $path = $photo->store('service-requests', 'public');

            ServiceRequestPhoto::create([
                'service_request_id' => $serviceRequest->id,
                'chemin_fichier' => $path,
            ]);
        }

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', $status === ServiceRequest::STATUS_DRAFT ? 'Brouillon mis à jour.' : 'Demande publiée.');
    }

    /**
     * Suppression définitive — uniquement pour un brouillon jamais publié.
     * Une demande déjà publiée/engagée doit être annulée (cancel), pas supprimée.
     */
    public function destroy(Request $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être supprimé.');

        foreach ($serviceRequest->photos as $photo) {
            Storage::disk('public')->delete($photo->chemin_fichier);
        }

        $serviceRequest->delete();

        return redirect()
            ->route('service-requests.index')
            ->with('success', 'Brouillon supprimé.');
    }

    /**
     * "Demandes disponibles" côté prestataire — demandes publiées qui
     * correspondent à ses services/zones déclarés, en excluant celles où
     * il a déjà envoyé un devis.
     */
    public function browse(Request $request): Response
    {
        $user = $request->user();
        abort_unless($user->estPrestataire, 403, "Cette page est réservée aux prestataires.");

        $providerProfile = \App\Models\ProviderProfile::where('user_id', $user->id)->first();
        $serviceIds = $providerProfile?->services()->pluck('services.id') ?? collect();
        $zoneIds = $providerProfile?->zones()->pluck('zones.id') ?? collect();

        $serviceRequests = ServiceRequest::query()
            ->where('status', ServiceRequest::STATUS_PUBLISHED)
            ->when($serviceIds->isNotEmpty(), function ($q) use ($serviceIds) {
                $q->whereHas(
                    'serviceCategory.services',
                    fn ($sq) => $sq->whereIn('services.id', $serviceIds)
                );
            })
            ->when($zoneIds->isNotEmpty(), fn ($q) => $q->whereIn('zone_id', $zoneIds))
            ->whereDoesntHave(
                'proposals',
                fn ($q) => $q->where('provider_profile_id', $providerProfile?->id)
            )
            ->with(['serviceCategory', 'zone', 'client'])
            ->latest()
            ->paginate(10);

        return Inertia::render('ServiceRequests/Browse', [
            'serviceRequests' => $serviceRequests,
        ]);
    }
}
