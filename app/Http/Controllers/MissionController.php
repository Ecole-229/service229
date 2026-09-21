<?php
namespace App\Http\Controllers;

use App\Models\Mission;
use App\Services\Marketplace\MissionService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class MissionController extends Controller
{
    public function __construct(private MissionService $missionService)
    {
    }

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

    public function start(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('start', $mission);

        $this->missionService->start($mission);

        return back()->with('success', 'Mission démarrée.');
    }

    public function markAwaitingConfirmation(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('markAwaitingConfirmation', $mission);

        $this->missionService->markAwaitingConfirmation($mission);

        return back()->with('success', 'En attente de confirmation du client.');
    }

    public function confirmCompletion(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('confirmCompletion', $mission);

        $this->missionService->confirmCompletion($mission);

        return back()->with('success', 'Mission terminée. Vous pouvez laisser un avis.');
    }

    public function markPaid(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('markPaid', $mission);

        $this->missionService->markPaid($mission);

        return back()->with('success', 'Paiement marqué comme effectué.');
    }

    public function cancel(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('cancel', $mission);

        $this->missionService->cancel($mission);

        return back()->with('success', 'Mission annulée.');
    }
}
