<?php
namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Services\Marketplace\ConversationService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ConversationController extends Controller
{
    public function __construct(private ConversationService $conversationService)
    {
    }

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

        $this->conversationService->markMessagesAsRead($conversation, $request->user());

        return Inertia::render('Conversations/Show', [
            'conversation' => $conversation,
        ]);
    }

    public function startOrFind(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'provider_profile_id' => ['nullable', 'exists:provider_profiles,id'],
            'client_id' => ['nullable', 'exists:users,id'],
        ]);

        $conversation = $this->conversationService->startOrFind(
            $request->user(),
            $validated['provider_profile_id'] ?? null,
            $validated['client_id'] ?? null,
        );

        return redirect()->route('conversations.show', $conversation);
    }
}
