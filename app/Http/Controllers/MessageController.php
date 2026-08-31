<?php
namespace App\Http\Controllers;

use App\Events\MessageSent;
use App\Http\Requests\StoreMessageRequest;
use App\Models\Conversation;
use App\Models\Message;

class MessageController extends Controller
{
    public function store(StoreMessageRequest $request, Conversation $conversation)
    {
        $this->authorize('sendMessage', $conversation);

        $message = Message::create([
            ...$request->validated(),
            'conversation_id' => $conversation->id,
            'sender_id' => $request->user()->id,
        ]);

        // Fait remonter la conversation en haut de la liste (tri par updated_at)
        $conversation->touch();

        MessageSent::dispatch($message);

        return back();
    }
}
