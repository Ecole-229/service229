<?php
namespace App\Policies;

use App\Models\Proposal;
use App\Models\User;

class ProposalPolicy
{
    public function acceptOrReject(User $user, Proposal $proposal): bool
    {
        return $proposal->serviceRequest->client_id === $user->id
            && $proposal->status === Proposal::STATUS_PENDING;
    }

    public function withdraw(User $user, Proposal $proposal): bool
    {
        return $proposal->providerProfile->user_id === $user->id
            && $proposal->status === Proposal::STATUS_PENDING;
    }
}
