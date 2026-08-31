<?php
namespace App\Listeners;

use App\Events\ReviewCreated;
use App\Models\Notification;

class NotifyProviderOfNewReview
{
    public function handle(ReviewCreated $event): void
    {
        $review = $event->review;
        $providerUserId = $review->providerProfile->user_id;

        Notification::create([
            'user_id' => $providerUserId,
            'type' => Notification::TYPE_NOUVEL_AVIS,
            'message' => "Vous avez reçu un avis ({$review->note}/5)",
            'lien_associe' => "/missions/{$review->mission_id}",
        ]);
    }
}
