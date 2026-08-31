<?php
namespace App\Listeners;

use App\Events\MessageSent;
use App\Models\Notification;

class NotifyRecipientOfNewMessage
{
    public function handle(MessageSent $event): void
    {
        $message = $event->message;
        $conversation = $message->conversation;

        // Le destinataire est celui des deux qui n'a PAS envoyé le message
        $recipientUserId = $message->sender_id === $conversation->client_id
            ? $conversation->providerProfile->user_id
            : $conversation->client_id;

        Notification::create([
            'user_id' => $recipientUserId,
            'type' => Notification::TYPE_NOUVEAU_MESSAGE,
            'message' => 'Nouveau message reçu',
            'lien_associe' => "/conversations/{$conversation->id}",
        ]);
    }
}
