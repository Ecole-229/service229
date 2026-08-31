<?php
namespace App\Policies;

use App\Models\Mission;
use App\Models\User;

class MissionPolicy
{
    public function view(User $user, Mission $mission): bool
    {
        return $this->isParticipant($user, $mission);
    }

    public function start(User $user, Mission $mission): bool
    {
        return $mission->providerProfile->user_id === $user->id
            && $mission->status === Mission::STATUS_PENDING;
    }

    public function markAwaitingConfirmation(User $user, Mission $mission): bool
    {
        return $mission->providerProfile->user_id === $user->id
            && $mission->status === Mission::STATUS_IN_PROGRESS;
    }

    public function confirmCompletion(User $user, Mission $mission): bool
    {
        return $mission->client_id === $user->id
            && $mission->status === Mission::STATUS_AWAITING_CONFIRMATION;
    }

    public function markPaid(User $user, Mission $mission): bool
    {
        return $mission->client_id === $user->id;
    }

    public function cancel(User $user, Mission $mission): bool
    {
        return $this->isParticipant($user, $mission)
            && ! in_array($mission->status, [Mission::STATUS_COMPLETED, Mission::STATUS_CANCELLED]);
    }

    private function isParticipant(User $user, Mission $mission): bool
    {
        return $mission->client_id === $user->id
            || $mission->providerProfile->user_id === $user->id;
    }
}
