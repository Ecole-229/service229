<?php
namespace App\Policies;

use App\Models\Mission;
use App\Models\Review;
use App\Models\User;

class ReviewPolicy
{
    public function create(User $user, Mission $mission): bool
    {
        return $mission->client_id === $user->id
            && $mission->isCompleted()
            && ! $mission->review()->exists();
    }

    public function update(User $user, Review $review): bool
    {
        return $review->client_id === $user->id;
    }
}
