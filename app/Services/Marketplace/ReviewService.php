<?php
namespace App\Services\Marketplace;

use App\Events\ReviewCreated;
use App\Models\Mission;
use App\Models\Review;

class ReviewService
{
    public function submit(Mission $mission, array $data): Review
    {
        abort_unless($mission->isCompleted(), 422, 'Impossible de laisser un avis avant la fin de la mission.');
        abort_if($mission->review()->exists(), 422, 'Un avis a déjà été laissé pour cette mission.');

        $review = Review::create([
            ...$data,
            'mission_id' => $mission->id,
            'client_id' => $mission->client_id,
            'provider_profile_id' => $mission->provider_profile_id,
        ]);

        ReviewCreated::dispatch($review);

        return $review;
    }

    public function update(Review $review, array $data): Review
    {
        $review->update($data);

        return $review->fresh();
    }
}
