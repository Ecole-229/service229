<?php
namespace App\Http\Controllers;

use App\Events\MissionCompleted;
use App\Models\Mission;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class MissionController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();

        $missions = Mission::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['serviceRequest', 'proposal', 'client', 'providerProfile.user', 'review'])
            ->latest()
            ->paginate(10);

        return Inertia::render('Missions/Index', [
            'missions' => $missions,
        ]);
    }

    public function show(Request $request, Mission $mission): Response
    {
        $this->authorize('view', $mission);

        $mission->load(['serviceRequest', 'proposal', 'client', 'providerProfile.user', 'review']);

        return Inertia::render('Missions/Show', [
            'mission' => $mission,
        ]);
    }

    /**
     * Le prestataire démarre la mission.
     */
    public function start(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('start', $mission);

        $mission->update(['status' => Mission::STATUS_IN_PROGRESS]);

        return back()->with('success', 'Mission démarrée.');
    }

    /**
     * Le prestataire signale que le travail est terminé de son côté.
     */
    public function markAwaitingConfirmation(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('markAwaitingConfirmation', $mission);

        $mission->update(['status' => Mission::STATUS_AWAITING_CONFIRMATION]);

        return back()->with('success', 'En attente de confirmation du client.');
    }

    /**
     * Le client confirme que le travail est bien terminé.
     */
    public function confirmCompletion(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('confirmCompletion', $mission);

        $mission->update(['status' => Mission::STATUS_COMPLETED]);

        $mission->serviceRequest->update(['status' => \App\Models\ServiceRequest::STATUS_CLOSED]);

        MissionCompleted::dispatch($mission->fresh());

        return back()->with('success', 'Mission terminée. Vous pouvez laisser un avis.');
    }

    /**
     * Le client indique que le paiement (hors plateforme) a bien été effectué.
     */
    public function markPaid(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('markPaid', $mission);

        $mission->update(['paiementEffectue' => true]);

        return back()->with('success', 'Paiement marqué comme effectué.');
    }

    /**
     * Annulation par le client ou le prestataire, tant que la mission
     * n'est pas déjà terminée.
     */
    public function cancel(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('cancel', $mission);

        $mission->update(['status' => Mission::STATUS_CANCELLED]);

        return back()->with('success', 'Mission annulée.');
    }
}
