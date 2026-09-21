<?php
namespace App\Http\Controllers;

use App\Http\Requests\StoreReviewRequest;
use App\Models\Mission;
use App\Models\Review;
use App\Services\Marketplace\ReviewService;
use Illuminate\Http\RedirectResponse;

class ReviewController extends Controller
{
    public function __construct(private ReviewService $reviewService)
    {
    }

    public function store(StoreReviewRequest $request, Mission $mission): RedirectResponse
    {
        $this->authorize('create', [Review::class, $mission]);

        $this->reviewService->submit($mission, $request->validated());

        return back()->with('success', 'Avis publié.');
    }

    public function update(StoreReviewRequest $request, Review $review): RedirectResponse
    {
        $this->authorize('update', $review);

        $this->reviewService->update($review, $request->validated());

        return back()->with('success', 'Avis modifié.');
    }
}
