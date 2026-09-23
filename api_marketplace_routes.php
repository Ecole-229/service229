<?php
// EMPLACEMENT : routes/api/marketplace.php
//
// Fichier AUTONOME — ne pas fusionner directement dans routes/api.php.
// Une fois que le socle Sanctum est en place, il suffit d'ajouter cette
// ligne dans routes/api.php :
//
//     require __DIR__.'/api/marketplace.php';
//
// Toutes les routes ci-dessous sont déjà préfixées "v1" et protégées par
// auth:sanctum — rien d'autre à configurer côté socle pour qu'elles marchent.

use App\Http\Controllers\Api\V1\ConversationController;
use App\Http\Controllers\Api\V1\MissionController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\ProposalController;
use App\Http\Controllers\Api\V1\ReviewController;
use App\Http\Controllers\Api\V1\SearchController;
use App\Http\Controllers\Api\V1\ServiceRequestController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->name('api.v1.')->group(function () {

    // Recherche/matching — publique, pas besoin de token
    Route::get('/search/providers', [SearchController::class, 'providers'])->name('search.providers');

    Route::middleware('auth:sanctum')->group(function () {
        // ServiceRequests
        Route::get('/service-requests', [ServiceRequestController::class, 'index'])->name('service-requests.index');
        Route::post('/service-requests', [ServiceRequestController::class, 'store'])->name('service-requests.store');
        Route::get('/service-requests/{serviceRequest}', [ServiceRequestController::class, 'show'])->name('service-requests.show');
        Route::put('/service-requests/{serviceRequest}', [ServiceRequestController::class, 'update'])->name('service-requests.update');

        // Proposals
        Route::get('/service-requests/{serviceRequest}/proposals', [ProposalController::class, 'index'])->name('proposals.index');
        Route::post('/service-requests/{serviceRequest}/proposals', [ProposalController::class, 'store'])->name('proposals.store');
        Route::post('/proposals/{proposal}/accept', [ProposalController::class, 'accept'])->name('proposals.accept');
        Route::post('/proposals/{proposal}/reject', [ProposalController::class, 'reject'])->name('proposals.reject');
        Route::post('/proposals/{proposal}/withdraw', [ProposalController::class, 'withdraw'])->name('proposals.withdraw');

        // Missions
        Route::get('/missions', [MissionController::class, 'index'])->name('missions.index');
        Route::get('/missions/{mission}', [MissionController::class, 'show'])->name('missions.show');
        Route::post('/missions/{mission}/start', [MissionController::class, 'start'])->name('missions.start');
        Route::post('/missions/{mission}/finish', [MissionController::class, 'finish'])->name('missions.finish');
        Route::post('/missions/{mission}/confirm', [MissionController::class, 'confirm'])->name('missions.confirm');
        Route::post('/missions/{mission}/dispute', [MissionController::class, 'dispute'])->name('missions.dispute');
        // Au-delà du minimum demandé, cohérent avec la version Inertia :
        Route::post('/missions/{mission}/mark-paid', [MissionController::class, 'markPaid'])->name('missions.mark-paid');
        Route::post('/missions/{mission}/cancel', [MissionController::class, 'cancel'])->name('missions.cancel');

        // Reviews
        Route::post('/missions/{mission}/reviews', [ReviewController::class, 'store'])->name('reviews.store');

        // Conversations & Messages
        Route::get('/conversations', [ConversationController::class, 'index'])->name('conversations.index');
        Route::get('/conversations/{conversation}/messages', [ConversationController::class, 'messages'])->name('conversations.messages');
        Route::post('/conversations/{conversation}/messages', [ConversationController::class, 'sendMessage'])->name('conversations.send-message');

        // Notifications
        Route::get('/notifications', [NotificationController::class, 'index'])->name('notifications.index');
        Route::post('/notifications/{notification}/read', [NotificationController::class, 'read'])->name('notifications.read');
    });
});
