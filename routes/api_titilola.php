<?php

use App\Http\Controllers\Api\V1\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Api\V1\Admin\ReferenceController as AdminReferenceController;
use App\Http\Controllers\Api\V1\ProviderController;
use App\Http\Controllers\Api\V1\ProviderProfileController;
use App\Http\Controllers\Api\V1\ServiceCategoryController;
use App\Http\Controllers\Api\V1\ServiceController;
use App\Http\Controllers\Api\V1\ZoneController;
use Illuminate\Support\Facades\Route;

Route::prefix("v1")->group(function () {
    // Référentiel public
    Route::get("categories", [ServiceCategoryController::class, "index"]);
    Route::get("categories/{category}", [ServiceCategoryController::class, "show"]);

    Route::get("services", [ServiceController::class, "index"]);
    Route::get("services/{service}", [ServiceController::class, "show"]);

    Route::get("zones", [ZoneController::class, "index"]);
    Route::get("zones/{zone}", [ZoneController::class, "show"]);

    // Prestataires publics
    Route::get("providers", [ProviderController::class, "index"]);
    Route::get("providers/{provider}", [ProviderController::class, "show"]);

    // Prestataire connecté
    Route::middleware("auth:sanctum")->group(function () {
        Route::get("provider-profile", [ProviderProfileController::class, "show"]);
        Route::put("provider-profile/services", [ProviderProfileController::class, "syncServices"]);
        Route::put("provider-profile/zones", [ProviderProfileController::class, "syncZones"]);
    });

    // Administration
    Route::middleware(["auth:sanctum", "admin"])
        ->prefix("admin")
        ->group(function () {
            Route::get("dashboard", AdminDashboardController::class);

            Route::post("categories", [AdminReferenceController::class, "storeCategory"]);
            Route::put("categories/{category}", [AdminReferenceController::class, "updateCategory"]);
            Route::delete("categories/{category}", [AdminReferenceController::class, "destroyCategory"]);

            Route::post("services", [AdminReferenceController::class, "storeService"]);
            Route::put("services/{service}", [AdminReferenceController::class, "updateService"]);
            Route::delete("services/{service}", [AdminReferenceController::class, "destroyService"]);

            Route::post("zones", [AdminReferenceController::class, "storeZone"]);
            Route::put("zones/{zone}", [AdminReferenceController::class, "updateZone"]);
            Route::delete("zones/{zone}", [AdminReferenceController::class, "destroyZone"]);
        });
});
