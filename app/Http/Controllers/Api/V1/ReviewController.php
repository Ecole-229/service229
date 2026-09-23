<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreReviewRequest;
use App\Http\Resources\ReviewResource;
use App\Models\Mission;
use App\Models\Review;
use App\Services\Marketplace\ReviewService;
use Illuminate\Http\JsonResponse;

class ReviewController extends Controller
{
    public function __construct(private ReviewService $reviewService)
    {
    }

    public function store(StoreReviewRequest $request, Mission $mission): JsonResponse
    {
        $this->authorize('create', [Review::class, $mission]);

        $review = $this->reviewService->submit($mission, $request->validated());

        return response()->json(['data' => new ReviewResource($review)], 201);
    }
}
