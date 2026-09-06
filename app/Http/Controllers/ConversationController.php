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
            ->with(['client', 'providerProfile.user', 'serviceRequest'])
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

        $conversation->load(['client', 'providerProfile.user', 'serviceRequest', 'messages.sender']);

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
     * Démarre (ou récupère) le fil unique client/prestataire. Fonctionne
     * dans les deux sens :
     * - Un client fournit "provider_profile_id" (il connaît le prestataire).
     * - Un prestataire fournit "client_id" (il répond à un client précis) ;
     *   son propre provider_profile_id est déduit automatiquement.
     */
    public function startOrFind(Request $request): RedirectResponse
    {
        $user = $request->user();

        if ($request->filled('client_id')) {
            // C'est un prestataire qui initie
            abort_unless($user->estPrestataire, 403);

            $providerProfile = ProviderProfile::where('user_id', $user->id)->firstOrFail();

            $validated = $request->validate([
                'client_id' => ['required', 'exists:users,id'],
            ]);

            $conversation = Conversation::firstOrCreate([
                'client_id' => $validated['client_id'],
                'provider_profile_id' => $providerProfile->id,
            ]);
        } else {
            // C'est un client qui initie
            $validated = $request->validate([
                'provider_profile_id' => ['required', 'exists:provider_profiles,id'],
            ]);

            $conversation = Conversation::firstOrCreate([
                'client_id' => $user->id,
                'provider_profile_id' => $validated['provider_profile_id'],
            ]);
        }

        return redirect()->route('conversations.show', $conversation);
    }
}
