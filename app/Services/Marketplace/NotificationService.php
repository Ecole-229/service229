<?php
namespace App\Services\Marketplace;

use App\Models\Notification;
use App\Models\User;

class NotificationService
{
    public function markAsRead(Notification $notification): void
    {
        $notification->update(['lu' => true]);
    }

    public function markAllAsRead(User $user): void
    {
        Notification::where('user_id', $user->id)
            ->where('lu', false)
            ->update(['lu' => true]);
    }
}
