<?php
namespace App\Listeners;

use App\Events\MissionCompleted;
use App\Models\Notification;

class NotifyClientMissionCompleted
{
    public function handle(MissionCompleted $event): void
    {
        $mission = $event->mission;

        Notification::create([
            'user_id' => $mission->client_id,
            'type' => Notification::TYPE_MISSION_TERMINEE,
            'message' => 'Votre mission est terminée. Vous pouvez laisser un avis.',
            'lien_associe' => "/missions/{$mission->id}",
        ]);
    }
}
