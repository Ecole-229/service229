<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMessageRequest;
use App\Http\Resources\ConversationResource;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Services\Marketplace\ConversationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationController extends Controller
{
    public function __construct(private ConversationService $conversationService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $conversations = Conversation::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['client', 'providerProfile.user', 'serviceRequest'])
            ->withCount(['messages as unread_count' => fn ($q) => $q->whereNull('read_at')->where('sender_id', '!=', $user->id)])
            ->latest('updated_at')
            ->get();

        return response()->json(['data' => ConversationResource::collection($conversations)]);
    }

    public function messages(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $this->conversationService->markMessagesAsRead($conversation, $request->user());

        return response()->json([
            'data' => MessageResource::collection($conversation->messages()->with('sender')->get()),
        ]);
    }

    public function sendMessage(StoreMessageRequest $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $message = $this->conversationService->sendMessage(
            $conversation,
            $request->user(),
            $request->validated()['content']
        );

        return response()->json(['data' => new MessageResource($message)], 201);
    }
}
