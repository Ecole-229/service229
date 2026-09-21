<?php
namespace App\Services\Marketplace;

use App\Events\MessageSent;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\ProviderProfile;
use App\Models\User;

class ConversationService
{
    /**
     * Démarre (ou récupère) le fil unique client/prestataire.
     * Fonctionne dans les deux sens :
     * - un client fournit providerProfileId ;
     * - un prestataire (identifié via $initiator->estPrestataire) fournit clientId.
     */
    public function startOrFind(User $initiator, ?int $providerProfileId, ?int $clientId): Conversation
    {
        if ($clientId !== null) {
            abort_unless($initiator->estPrestataire, 403);

            $providerProfile = ProviderProfile::where('user_id', $initiator->id)->firstOrFail();

            return Conversation::firstOrCreate([
                'client_id' => $clientId,
                'provider_profile_id' => $providerProfile->id,
            ]);
        }

        return Conversation::firstOrCreate([
            'client_id' => $initiator->id,
            'provider_profile_id' => $providerProfileId,
        ]);
    }

    public function sendMessage(Conversation $conversation, User $sender, string $content): Message
    {
        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $sender->id,
            'content' => $content,
        ]);

        $conversation->touch();

        MessageSent::dispatch($message);

        return $message;
    }

    public function markMessagesAsRead(Conversation $conversation, User $reader): void
    {
        $conversation->messages()
            ->whereNull('read_at')
            ->where('sender_id', '!=', $reader->id)
            ->update(['read_at' => now()]);
    }
}
