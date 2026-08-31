<?php
namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Models\ProviderProfile;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ConversationController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();

        $conversations = Conversation::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['client', 'providerProfile', 'serviceRequest'])
            ->withCount(['messages as unread_count' => fn ($q) => $q->whereNull('read_at')->where('sender_id', '!=', $user->id)])
            ->latest('updated_at')
            ->get();

        return Inertia::render('Conversations/Index', [
            'conversations' => $conversations,
        ]);
    }

    public function show(Request $request, Conversation $conversation): Response
    {
        $this->authorize('view', $conversation);

        $conversation->load(['client', 'providerProfile', 'serviceRequest', 'messages.sender']);

        // Marquer comme lus les messages de l'autre personne
        $conversation->messages()
            ->whereNull('read_at')
            ->where('sender_id', '!=', $request->user()->id)
            ->update(['read_at' => now()]);

        return Inertia::render('Conversations/Show', [
            'conversation' => $conversation,
        ]);
    }

    /**
     * Démarre (ou récupère) le fil unique client/prestataire — "discuter avant
     * de faire une demande". Un seul fil possible par duo (voir migration).
     */
    public function startOrFind(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'provider_profile_id' => ['required', 'exists:provider_profiles,id'],
        ]);

        $conversation = Conversation::firstOrCreate([
            'client_id' => $request->user()->id,
            'provider_profile_id' => $validated['provider_profile_id'],
        ]);

        return redirect()->route('conversations.show', $conversation);
    }
}
