<?php
namespace App\Http\Controllers;

use App\Events\ReviewCreated;
use App\Http\Requests\StoreReviewRequest;
use App\Models\Mission;
use App\Models\Review;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    /**
     * Le client laisse un avis sur une mission terminée.
     */
    public function store(StoreReviewRequest $request, Mission $mission): RedirectResponse
    {
        $this->authorize('create', [Review::class, $mission]);

        $review = Review::create([
            ...$request->validated(),
            'mission_id' => $mission->id,
            'client_id' => $mission->client_id,
            'provider_profile_id' => $mission->provider_profile_id,
        ]);

        ReviewCreated::dispatch($review);

        return back()->with('success', 'Avis publié.');
    }

    /**
     * Le client peut corriger son avis après coup.
     */
    public function update(StoreReviewRequest $request, Review $review): RedirectResponse
    {
        $this->authorize('update', $review);

        $review->update($request->validated());

        return back()->with('success', 'Avis modifié.');
    }
}
