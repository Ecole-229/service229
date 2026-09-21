<?php
namespace App\Http\Controllers;

use App\Http\Requests\StoreMessageRequest;
use App\Models\Conversation;
use App\Services\Marketplace\ConversationService;

class MessageController extends Controller
{
    public function __construct(private ConversationService $conversationService)
    {
    }

    public function store(StoreMessageRequest $request, Conversation $conversation)
    {
        $this->authorize('sendMessage', $conversation);

        $this->conversationService->sendMessage(
            $conversation,
            $request->user(),
            $request->validated()['content']
        );

        return back();
    }
}
