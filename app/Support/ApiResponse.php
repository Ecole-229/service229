<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;
use Illuminate\Pagination\LengthAwarePaginator;

trait ApiResponse
{
    protected function success(
        mixed $data = null,
        string $message = "OK",
        int $status = 200
    ): JsonResponse {
        return response()->json([
            "success" => true,
            "message" => $message,
            "data" => $data,
        ], $status);
    }

    protected function paginated(
        LengthAwarePaginator $paginator,
        array $items,
        string $message = "OK"
    ): JsonResponse {
        return response()->json([
            "success" => true,
            "message" => $message,
            "data" => $items,
            "meta" => [
                "current_page" => $paginator->currentPage(),
                "last_page" => $paginator->lastPage(),
                "per_page" => $paginator->perPage(),
                "total" => $paginator->total(),
            ],
        ]);
    }

    protected function error(
        string $message,
        int $status = 422,
        array $errors = []
    ): JsonResponse {
        return response()->json([
            "success" => false,
            "message" => $message,
            "errors" => $errors,
        ], $status);
    }
}
