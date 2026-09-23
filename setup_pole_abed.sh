#!/bin/bash
# Script complet — Backend (Services + Controllers Inertia + API V1 + Resources)
# + Frontend du pôle Demandes & Mise en relation — Service229
# routes/api_abed.php est maintenant placé directement (fichier neuf, aucun risque)
# À lancer depuis LA RACINE du projet Laravel (là où se trouve artisan)
set -e

echo "== Backend =="

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_090000_add_est_client_et_est_prestataire_to_users_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('estClient')->default(true);
            $table->boolean('estPrestataire')->default(false);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['estClient', 'estPrestataire']);
        });
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_090100_create_provider_profiles_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('provider_profiles', function (Blueprint $table) {
            $table->id();

            // Convention Laravel standard — à confirmer avec Victorius
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_profiles');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_090200_create_service_categories_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_categories');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_090250_create_services_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('services', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')
                ->constrained('service_categories')
                ->cascadeOnUpdate()
                ->restrictOnDelete();
            $table->string('name');
            $table->timestamps();

            $table->unique(['category_id', 'name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('services');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_090300_create_zones_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('zones', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('zones');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_090500_create_provider_services_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('provider_services', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_profile_id')
                ->constrained('provider_profiles')
                ->cascadeOnDelete();

            $table->foreignId('service_id')
                ->constrained('services')
                ->cascadeOnDelete();

            $table->timestamps();

            $table->unique(['provider_profile_id', 'service_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_services');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_090600_create_provider_zones_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('provider_zones', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_profile_id')
                ->constrained('provider_profiles')
                ->cascadeOnDelete();

            $table->foreignId('zone_id')
                ->constrained('zones')
                ->cascadeOnDelete();

            $table->timestamps();

            $table->unique(['provider_profile_id', 'zone_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_zones');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_100000_create_service_requests_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_requests', function (Blueprint $table) {
            $table->id();

            // Client qui crée la demande
            $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();

            // Catégorie + zone (référentiel géré par Mme Titilola)
            $table->foreignId('service_category_id')->constrained('service_categories')->restrictOnDelete();
            $table->foreignId('zone_id')->constrained('zones')->restrictOnDelete();

            // Renseigné uniquement en Mode 1 (recherche directe / contact direct)
            // Reste null en Mode 2 (publication d'un besoin ouvert)
            $table->foreignId('provider_profile_id')->nullable()
                ->constrained('provider_profiles')->nullOnDelete();

            $table->string('title');
            $table->text('description')->nullable();

            // Statuts figés — section 4.1 du document de référence
            $table->enum('status', [
                'draft',
                'published',
                'matched',
                'assigned',
                'cancelled',
                'expired',
                'closed',
            ])->default('draft');

            $table->timestamps();

            $table->index(['status', 'service_category_id', 'zone_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_requests');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_100100_create_proposals_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('proposals', function (Blueprint $table) {
            $table->id();

            $table->foreignId('service_request_id')->constrained('service_requests')->cascadeOnDelete();
            $table->foreignId('provider_profile_id')->constrained('provider_profiles')->cascadeOnDelete();

            // "un Proposal (devis) contenant montant, délai et description" — section 2.3
            $table->decimal('montant', 10, 2);
            $table->string('delai'); // ex: "3 jours", "sous 48h" — texte libre du prestataire
            $table->text('description');

            // Statuts figés — section 4.2 du document de référence
            $table->enum('status', [
                'pending',
                'accepted',
                'rejected',
                'withdrawn',
            ])->default('pending');

            $table->timestamps();

            // Un prestataire ne peut avoir qu'un devis actif par demande
            $table->unique(['service_request_id', 'provider_profile_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('proposals');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_100200_create_missions_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('missions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('service_request_id')->constrained('service_requests')->restrictOnDelete();
            $table->foreignId('proposal_id')->constrained('proposals')->restrictOnDelete();

            // Dénormalisés depuis service_request/proposal pour des requêtes simples
            $table->foreignId('client_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('provider_profile_id')->constrained('provider_profiles')->restrictOnDelete();

            // Statuts figés — section 4.3 du document de référence
            $table->enum('status', [
                'pending',
                'in_progress',
                'awaiting_confirmation',
                'completed',
                'cancelled',
                'disputed',
            ])->default('pending');

            // Paiement hors plateforme — section 2.4 : simple booléen de suivi
            $table->boolean('paiementEffectue')->default(false);

            $table->timestamps();

            $table->unique('service_request_id');
            $table->unique('proposal_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('missions');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_100300_create_conversations_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();

            // Toujours nullable : le duo peut discuter "de tout et de rien"
            // avant même que le client ne formalise une demande.
            // Sert de référence à LA demande en cours de discussion (facultatif,
            // ne bloque rien si la conversation dérive vers un autre sujet ensuite).
            $table->foreignId('service_request_id')->nullable()
                ->constrained('service_requests')->nullOnDelete();

            $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('provider_profile_id')->constrained('provider_profiles')->cascadeOnDelete();

            $table->timestamps();

            // Un seul fil de discussion possible entre un client et un prestataire donné,
            // peu importe le nombre de demandes qu'ils traiteront ensemble dans le temps.
            $table->unique(['client_id', 'provider_profile_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conversations');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_100400_create_messages_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();

            $table->foreignId('conversation_id')->constrained('conversations')->cascadeOnDelete();

            // Celui qui envoie le message (client OU prestataire, tous deux dans users)
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();

            $table->text('content');

            // Pour savoir si le destinataire a lu le message (utile pour les notifications)
            $table->timestamp('read_at')->nullable();

            $table->timestamps();

            $table->index('conversation_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_100500_create_reviews_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();

            // Un avis est toujours laissé sur une mission terminée précise
            $table->foreignId('mission_id')->constrained('missions')->cascadeOnDelete();

            // Répétés ici pour interroger facilement "tous les avis d'un prestataire"
            // sans repasser par missions -> proposals -> service_requests
            $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('provider_profile_id')->constrained('provider_profiles')->cascadeOnDelete();

            $table->unsignedTinyInteger('note'); // note de 1 à 5
            $table->text('commentaire')->nullable();

            $table->timestamps();

            // Un seul avis possible par mission
            $table->unique('mission_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_100600_create_notifications_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();

            // Le destinataire de la notification
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();

            // Type fermé et connu à l'avance (liste définie dans le code, pas en base)
            // ex: nouvelle_proposal, proposal_acceptee, mission_terminee, nouveau_message, nouvel_avis
            $table->string('type');

            $table->string('message');

            // Lien vers la page concernée côté Vue (ex: /missions/12)
            // Simple pour l'instant, pourra devenir polymorphe plus tard si besoin
            $table->string('lien_associe')->nullable();

            $table->boolean('lu')->default(false);

            $table->timestamps();

            $table->index(['user_id', 'lu']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_100700_add_budget_and_date_to_service_requests_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_requests', function (Blueprint $table) {
            // Champs présents dans la maquette (web + mobile), absents du
            // document texte initial — ajoutés en nullable, aucune donnée
            // existante affectée.
            $table->decimal('budget_estime', 10, 2)->nullable()->after('description');
            $table->date('date_intervention')->nullable()->after('budget_estime');
        });
    }

    public function down(): void
    {
        Schema::table('service_requests', function (Blueprint $table) {
            $table->dropColumn(['budget_estime', 'date_intervention']);
        });
    }
};
PHPEOF

mkdir -p "database/migrations"
cat > "database/migrations/2026_08_20_100800_create_service_request_photos_table.php" << 'PHPEOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_request_photos', function (Blueprint $table) {
            $table->id();

            $table->foreignId('service_request_id')->constrained('service_requests')->cascadeOnDelete();

            // Chemin relatif sur le disque "public" (ex: service-requests/xyz.jpg)
            $table->string('chemin_fichier');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_request_photos');
    }
};
PHPEOF

mkdir -p "app/Http/Controllers/Api/V1"
cat > "app/Http/Controllers/Api/V1/ConversationController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMessageRequest;
use App\Http\Resources\ConversationResource;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Services\Marketplace\ConversationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationController extends Controller
{
    public function __construct(private ConversationService $conversationService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $conversations = Conversation::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['client', 'providerProfile.user', 'serviceRequest'])
            ->withCount(['messages as unread_count' => fn ($q) => $q->whereNull('read_at')->where('sender_id', '!=', $user->id)])
            ->latest('updated_at')
            ->get();

        return response()->json(['data' => ConversationResource::collection($conversations)]);
    }

    public function messages(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $this->conversationService->markMessagesAsRead($conversation, $request->user());

        return response()->json([
            'data' => MessageResource::collection($conversation->messages()->with('sender')->get()),
        ]);
    }

    public function sendMessage(StoreMessageRequest $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $message = $this->conversationService->sendMessage(
            $conversation,
            $request->user(),
            $request->validated()['content']
        );

        return response()->json(['data' => new MessageResource($message)], 201);
    }
}
PHPEOF

mkdir -p "app/Http/Controllers/Api/V1"
cat > "app/Http/Controllers/Api/V1/MissionController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\MissionResource;
use App\Models\Mission;
use App\Services\Marketplace\MissionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MissionController extends Controller
{
    public function __construct(private MissionService $missionService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $missions = Mission::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['serviceRequest', 'client', 'providerProfile.user', 'review'])
            ->latest()
            ->paginate(15);

        return response()->json([
            'data' => MissionResource::collection($missions),
            'meta' => [
                'current_page' => $missions->currentPage(),
                'last_page' => $missions->lastPage(),
                'total' => $missions->total(),
            ],
        ]);
    }

    public function show(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('view', $mission);

        $mission->load(['serviceRequest', 'client', 'providerProfile.user', 'review']);

        return response()->json(['data' => new MissionResource($mission)]);
    }

    public function start(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('start', $mission);

        $this->missionService->start($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }

    /**
     * Le prestataire signale que le travail est terminé.
     */
    public function finish(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('markAwaitingConfirmation', $mission);

        $this->missionService->markAwaitingConfirmation($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }

    /**
     * Le client confirme la fin des travaux.
     */
    public function confirm(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('confirmCompletion', $mission);

        $this->missionService->confirmCompletion($mission);

        return response()->json(['data' => new MissionResource($mission->fresh()->load('review'))]);
    }

    public function dispute(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('dispute', $mission);

        $this->missionService->dispute($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }

    // --- Endpoints supplémentaires (au-delà du minimum demandé) ---

    public function markPaid(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('markPaid', $mission);

        $this->missionService->markPaid($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }

    public function cancel(Request $request, Mission $mission): JsonResponse
    {
        $this->authorize('cancel', $mission);

        $this->missionService->cancel($mission);

        return response()->json(['data' => new MissionResource($mission->fresh())]);
    }
}
PHPEOF

mkdir -p "app/Http/Controllers/Api/V1"
cat > "app/Http/Controllers/Api/V1/NotificationController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use App\Services\Marketplace\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function __construct(private NotificationService $notificationService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $notifications = Notification::where('user_id', $request->user()->id)
            ->latest()
            ->paginate(20);

        return response()->json([
            'data' => NotificationResource::collection($notifications),
            'meta' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'total' => $notifications->total(),
            ],
        ]);
    }

    public function read(Request $request, Notification $notification): JsonResponse
    {
        abort_unless($notification->user_id === $request->user()->id, 403);

        $this->notificationService->markAsRead($notification);

        return response()->json(['data' => new NotificationResource($notification->fresh())]);
    }
}
PHPEOF

mkdir -p "app/Http/Controllers/Api/V1"
cat > "app/Http/Controllers/Api/V1/ProposalController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreProposalRequest;
use App\Http\Resources\MissionResource;
use App\Http\Resources\ProposalResource;
use App\Models\Proposal;
use App\Models\ProviderProfile;
use App\Models\ServiceRequest;
use App\Services\Marketplace\ProposalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProposalController extends Controller
{
    public function __construct(private ProposalService $proposalService)
    {
    }

    public function index(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->authorize('view', $serviceRequest);

        return response()->json([
            'data' => ProposalResource::collection(
                $serviceRequest->proposals()->with('providerProfile.user')->get()
            ),
        ]);
    }

    public function store(StoreProposalRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $providerProfile = ProviderProfile::where('user_id', $request->user()->id)->first();
        abort_unless($providerProfile, 422, "Vous n'avez pas encore de profil prestataire.");

        $proposal = $this->proposalService->submit($serviceRequest, $providerProfile, $request->validated());

        return response()->json(['data' => new ProposalResource($proposal)], 201);
    }

    public function accept(Request $request, Proposal $proposal): JsonResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $mission = $this->proposalService->accept($proposal);

        return response()->json(['data' => new MissionResource($mission)]);
    }

    public function reject(Request $request, Proposal $proposal): JsonResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $this->proposalService->reject($proposal);

        return response()->json(['data' => new ProposalResource($proposal->fresh())]);
    }

    public function withdraw(Request $request, Proposal $proposal): JsonResponse
    {
        $this->authorize('withdraw', $proposal);

        $this->proposalService->withdraw($proposal);

        return response()->json(['data' => new ProposalResource($proposal->fresh())]);
    }
}
PHPEOF

mkdir -p "app/Http/Controllers/Api/V1"
cat > "app/Http/Controllers/Api/V1/ReviewController.php" << 'PHPEOF'
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
PHPEOF

mkdir -p "app/Http/Controllers/Api/V1"
cat > "app/Http/Controllers/Api/V1/SearchController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProviderProfileResource;
use App\Services\Marketplace\SearchService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function __construct(private SearchService $searchService)
    {
    }

    public function providers(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'service_category_id' => ['nullable', 'integer', 'exists:service_categories,id'],
            'zone_id' => ['nullable', 'integer', 'exists:zones,id'],
        ]);

        $providers = $this->searchService->searchProviders(
            $validated['service_category_id'] ?? null,
            $validated['zone_id'] ?? null,
        );

        return response()->json([
            'data' => ProviderProfileResource::collection($providers),
        ]);
    }
}
PHPEOF

mkdir -p "app/Http/Controllers/Api/V1"
cat > "app/Http/Controllers/Api/V1/ServiceRequestController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreServiceRequestRequest;
use App\Http\Resources\ServiceRequestResource;
use App\Models\ServiceRequest;
use App\Services\Marketplace\ServiceRequestService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ServiceRequestController extends Controller
{
    public function __construct(private ServiceRequestService $serviceRequestService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $serviceRequests = ServiceRequest::query()
            ->where('client_id', $request->user()->id)
            ->with(['serviceCategory', 'zone', 'proposals'])
            ->withCount('proposals')
            ->latest()
            ->paginate(15);

        return response()->json([
            'data' => ServiceRequestResource::collection($serviceRequests),
            'meta' => [
                'current_page' => $serviceRequests->currentPage(),
                'last_page' => $serviceRequests->lastPage(),
                'total' => $serviceRequests->total(),
            ],
        ]);
    }

    public function store(StoreServiceRequestRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $serviceRequest = $this->serviceRequestService->create(
            $request->user(),
            $validated,
            $photos,
            $request->boolean('as_draft')
        );

        return response()->json([
            'data' => new ServiceRequestResource($serviceRequest->load(['serviceCategory', 'zone'])),
        ], 201);
    }

    public function show(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->authorize('view', $serviceRequest);

        $serviceRequest->load(['serviceCategory', 'zone', 'proposals.providerProfile.user', 'photos']);

        return response()->json([
            'data' => new ServiceRequestResource($serviceRequest),
        ]);
    }

    public function update(StoreServiceRequestRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être modifié.');

        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $serviceRequest = $this->serviceRequestService->update(
            $serviceRequest,
            $validated,
            $photos,
            $request->boolean('as_draft')
        );

        return response()->json([
            'data' => new ServiceRequestResource($serviceRequest->load(['serviceCategory', 'zone'])),
        ]);
    }
}
PHPEOF

mkdir -p "app/Providers"
cat > "app/Providers/AuthServiceProvider.php" << 'PHPEOF'
<?php
namespace App\Providers;

use App\Models\Conversation;
use App\Models\Mission;
use App\Models\Proposal;
use App\Models\Review;
use App\Models\ServiceRequest;
use App\Policies\ConversationPolicy;
use App\Policies\MissionPolicy;
use App\Policies\ProposalPolicy;
use App\Policies\ReviewPolicy;
use App\Policies\ServiceRequestPolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [
        ServiceRequest::class => ServiceRequestPolicy::class,
        Proposal::class => ProposalPolicy::class,
        Mission::class => MissionPolicy::class,
        Review::class => ReviewPolicy::class,
        Conversation::class => ConversationPolicy::class,
    ];

    public function boot(): void
    {
        $this->registerPolicies();
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/Controller.php" << 'PHPEOF'
<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

abstract class Controller
{
    use AuthorizesRequests;
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/Conversation.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Conversation extends Model
{
    protected $fillable = [
        'service_request_id',
        'client_id',
        'provider_profile_id',
    ];

    // --- Relations ---

    // Nullable : référence la demande actuellement en cours de discussion,
    // le fil reste unique par duo client/prestataire (voir migration)
    public function serviceRequest(): BelongsTo
    {
        return $this->belongsTo(ServiceRequest::class);
    }

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function providerProfile(): BelongsTo
    {
        return $this->belongsTo(ProviderProfile::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/ConversationController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Services\Marketplace\ConversationService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ConversationController extends Controller
{
    public function __construct(private ConversationService $conversationService)
    {
    }

    public function index(Request $request): Response
    {
        $user = $request->user();

        $conversations = Conversation::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['client', 'providerProfile.user', 'serviceRequest'])
            ->withCount(['messages as unread_count' => fn ($q) => $q->whereNull('read_at')->where('sender_id', '!=', $user->id)])
            ->latest('updated_at')
            ->get();

        return Inertia::render('Conversations/Index', [
            'conversations' => $conversations,
        ]);
    }

    public function show(Request $request, Conversation $conversation): Response
    {
        $this->authorize('view', $conversation);

        $conversation->load(['client', 'providerProfile.user', 'serviceRequest', 'messages.sender']);

        $this->conversationService->markMessagesAsRead($conversation, $request->user());

        return Inertia::render('Conversations/Show', [
            'conversation' => $conversation,
        ]);
    }

    public function startOrFind(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'provider_profile_id' => ['nullable', 'exists:provider_profiles,id'],
            'client_id' => ['nullable', 'exists:users,id'],
        ]);

        $conversation = $this->conversationService->startOrFind(
            $request->user(),
            $validated['provider_profile_id'] ?? null,
            $validated['client_id'] ?? null,
        );

        return redirect()->route('conversations.show', $conversation);
    }
}
PHPEOF

mkdir -p "app/Policies"
cat > "app/Policies/ConversationPolicy.php" << 'PHPEOF'
<?php
namespace App\Policies;

use App\Models\Conversation;
use App\Models\User;

class ConversationPolicy
{
    public function view(User $user, Conversation $conversation): bool
    {
        return $this->isParticipant($user, $conversation);
    }

    public function sendMessage(User $user, Conversation $conversation): bool
    {
        return $this->isParticipant($user, $conversation);
    }

    private function isParticipant(User $user, Conversation $conversation): bool
    {
        return $conversation->client_id === $user->id
            || $conversation->providerProfile->user_id === $user->id;
    }
}
PHPEOF

mkdir -p "app/Http/Resources"
cat > "app/Http/Resources/ConversationResource.php" << 'PHPEOF'
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'client' => $this->whenLoaded('client', fn () => [
                'id' => $this->client->id,
                'name' => $this->client->name,
            ]),
            'provider_profile' => $this->whenLoaded('providerProfile', fn () => [
                'id' => $this->providerProfile->id,
                'name' => $this->providerProfile->user?->name,
            ]),
            'service_request' => $this->whenLoaded('serviceRequest', fn () => $this->serviceRequest ? [
                'id' => $this->serviceRequest->id,
                'title' => $this->serviceRequest->title,
            ] : null),
            'unread_count' => $this->whenCounted('unread_count', $this->unread_count ?? null),
            'messages' => MessageResource::collection($this->whenLoaded('messages')),
            'updated_at' => $this->updated_at,
        ];
    }
}
PHPEOF

mkdir -p "app/Services/Marketplace"
cat > "app/Services/Marketplace/ConversationService.php" << 'PHPEOF'
<?php
namespace App\Services\Marketplace;

use App\Events\MessageSent;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\ProviderProfile;
use App\Models\User;

class ConversationService
{
    /**
     * Démarre (ou récupère) le fil unique client/prestataire.
     * Fonctionne dans les deux sens :
     * - un client fournit providerProfileId ;
     * - un prestataire (identifié via $initiator->estPrestataire) fournit clientId.
     */
    public function startOrFind(User $initiator, ?int $providerProfileId, ?int $clientId): Conversation
    {
        if ($clientId !== null) {
            abort_unless($initiator->estPrestataire, 403);

            $providerProfile = ProviderProfile::where('user_id', $initiator->id)->firstOrFail();

            return Conversation::firstOrCreate([
                'client_id' => $clientId,
                'provider_profile_id' => $providerProfile->id,
            ]);
        }

        return Conversation::firstOrCreate([
            'client_id' => $initiator->id,
            'provider_profile_id' => $providerProfileId,
        ]);
    }

    public function sendMessage(Conversation $conversation, User $sender, string $content): Message
    {
        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $sender->id,
            'content' => $content,
        ]);

        $conversation->touch();

        MessageSent::dispatch($message);

        return $message;
    }

    public function markMessagesAsRead(Conversation $conversation, User $reader): void
    {
        $conversation->messages()
            ->whereNull('read_at')
            ->where('sender_id', '!=', $reader->id)
            ->update(['read_at' => now()]);
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/DashboardController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers;

use App\Models\Mission;
use App\Models\ServiceRequest;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();

        $baseQuery = ServiceRequest::where('client_id', $user->id);

        $stats = [
            'demandes_actives' => (clone $baseQuery)->whereNotIn('status', [
                ServiceRequest::STATUS_CLOSED,
                ServiceRequest::STATUS_CANCELLED,
                ServiceRequest::STATUS_EXPIRED,
            ])->count(),
            'propositions_recues' => \App\Models\Proposal::whereHas(
                'serviceRequest',
                fn ($q) => $q->where('client_id', $user->id)
            )->where('status', 'pending')->count(),
            'missions_en_cours' => Mission::where('client_id', $user->id)
                ->whereNotIn('status', [Mission::STATUS_COMPLETED, Mission::STATUS_CANCELLED])
                ->count(),
            'missions_terminees' => Mission::where('client_id', $user->id)
                ->where('status', Mission::STATUS_COMPLETED)
                ->count(),
        ];

        $recentServiceRequests = (clone $baseQuery)
            ->with(['serviceCategory', 'zone', 'proposals'])
            ->latest()
            ->take(5)
            ->get();

        return Inertia::render('Dashboard', [
            'stats' => $stats,
            'recentServiceRequests' => $recentServiceRequests,
        ]);
    }
}
PHPEOF

mkdir -p "app/Providers"
cat > "app/Providers/EventServiceProvider.php" << 'PHPEOF'
<?php
namespace App\Providers;

use App\Events\MessageSent;
use App\Events\MissionCompleted;
use App\Events\ProposalAccepted;
use App\Events\ProposalCreated;
use App\Events\ReviewCreated;
use App\Listeners\NotifyClientMissionCompleted;
use App\Listeners\NotifyClientOfNewProposal;
use App\Listeners\NotifyProviderOfNewReview;
use App\Listeners\NotifyProviderOfProposalAccepted;
use App\Listeners\NotifyRecipientOfNewMessage;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    /**
     * Mapping Event -> Listener(s).
     * Ajoute ici toute nouvelle notification automatique (section "Notifications"
     * du document de référence : jamais de création manuelle, toujours via Event).
     */
    protected $listen = [
        ProposalCreated::class => [
            NotifyClientOfNewProposal::class,
        ],
        ProposalAccepted::class => [
            NotifyProviderOfProposalAccepted::class,
        ],
        MissionCompleted::class => [
            NotifyClientMissionCompleted::class,
        ],
        MessageSent::class => [
            NotifyRecipientOfNewMessage::class,
        ],
        ReviewCreated::class => [
            NotifyProviderOfNewReview::class,
        ],
    ];

    public function boot(): void
    {
        //
    }
}
PHPEOF

mkdir -p "tests/Feature"
cat > "tests/Feature/ExampleTest.php" << 'PHPEOF'
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    /**
     * A basic test example.
     */
    public function test_the_application_returns_a_successful_response(): void
    {
        $response = $this->get('/');

        $response->assertStatus(200);
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/Message.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    protected $fillable = [
        'conversation_id',
        'sender_id',
        'content',
        'read_at',
    ];

    protected $casts = [
        'read_at' => 'datetime',
    ];

    // --- Relations ---

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    // Le client OU le prestataire — tous deux stockés dans users
    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    // --- Helpers ---

    public function isRead(): bool
    {
        return $this->read_at !== null;
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/MessageController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers;

use App\Http\Requests\StoreMessageRequest;
use App\Models\Conversation;
use App\Services\Marketplace\ConversationService;

class MessageController extends Controller
{
    public function __construct(private ConversationService $conversationService)
    {
    }

    public function store(StoreMessageRequest $request, Conversation $conversation)
    {
        $this->authorize('sendMessage', $conversation);

        $this->conversationService->sendMessage(
            $conversation,
            $request->user(),
            $request->validated()['content']
        );

        return back();
    }
}
PHPEOF

mkdir -p "app/Http/Resources"
cat > "app/Http/Resources/MessageResource.php" << 'PHPEOF'
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'content' => $this->content,
            'sender_id' => $this->sender_id,
            'read_at' => $this->read_at,
            'created_at' => $this->created_at,
        ];
    }
}
PHPEOF

mkdir -p "app/Events"
cat > "app/Events/MessageSent.php" << 'PHPEOF'
<?php
namespace App\Events;

use App\Models\Message;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent
{
    use Dispatchable, SerializesModels;

    public function __construct(public Message $message)
    {
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/Mission.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Mission extends Model
{
    // Statuts figés — section 4.3 du document de référence
    public const STATUS_PENDING = 'pending';
    public const STATUS_IN_PROGRESS = 'in_progress';
    public const STATUS_AWAITING_CONFIRMATION = 'awaiting_confirmation';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_CANCELLED = 'cancelled';
    public const STATUS_DISPUTED = 'disputed';

    protected $fillable = [
        'service_request_id',
        'proposal_id',
        'client_id',
        'provider_profile_id',
        'status',
        'paiementEffectue',
    ];

    protected $casts = [
        'paiementEffectue' => 'boolean',
    ];

    // --- Relations ---

    public function serviceRequest(): BelongsTo
    {
        return $this->belongsTo(ServiceRequest::class);
    }

    public function proposal(): BelongsTo
    {
        return $this->belongsTo(Proposal::class);
    }

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function providerProfile(): BelongsTo
    {
        return $this->belongsTo(ProviderProfile::class);
    }

    public function review(): HasOne
    {
        return $this->hasOne(Review::class);
    }

    // --- Helpers ---

    public function isCompleted(): bool
    {
        return $this->status === self::STATUS_COMPLETED;
    }
}
PHPEOF

mkdir -p "app/Events"
cat > "app/Events/MissionCompleted.php" << 'PHPEOF'
<?php
namespace App\Events;

use App\Models\Mission;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MissionCompleted
{
    use Dispatchable, SerializesModels;

    public function __construct(public Mission $mission)
    {
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/MissionController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers;

use App\Models\Mission;
use App\Services\Marketplace\MissionService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class MissionController extends Controller
{
    public function __construct(private MissionService $missionService)
    {
    }

    public function index(Request $request): Response
    {
        $user = $request->user();

        $missions = Mission::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['serviceRequest', 'proposal', 'client', 'providerProfile.user', 'review'])
            ->latest()
            ->paginate(10);

        return Inertia::render('Missions/Index', [
            'missions' => $missions,
        ]);
    }

    public function show(Request $request, Mission $mission): Response
    {
        $this->authorize('view', $mission);

        $mission->load(['serviceRequest', 'proposal', 'client', 'providerProfile.user', 'review']);

        return Inertia::render('Missions/Show', [
            'mission' => $mission,
        ]);
    }

    public function start(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('start', $mission);

        $this->missionService->start($mission);

        return back()->with('success', 'Mission démarrée.');
    }

    public function markAwaitingConfirmation(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('markAwaitingConfirmation', $mission);

        $this->missionService->markAwaitingConfirmation($mission);

        return back()->with('success', 'En attente de confirmation du client.');
    }

    public function confirmCompletion(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('confirmCompletion', $mission);

        $this->missionService->confirmCompletion($mission);

        return back()->with('success', 'Mission terminée. Vous pouvez laisser un avis.');
    }

    public function markPaid(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('markPaid', $mission);

        $this->missionService->markPaid($mission);

        return back()->with('success', 'Paiement marqué comme effectué.');
    }

    public function cancel(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('cancel', $mission);

        $this->missionService->cancel($mission);

        return back()->with('success', 'Mission annulée.');
    }
}
PHPEOF

mkdir -p "app/Policies"
cat > "app/Policies/MissionPolicy.php" << 'PHPEOF'
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

    public function dispute(User $user, Mission $mission): bool
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
PHPEOF

mkdir -p "app/Http/Resources"
cat > "app/Http/Resources/MissionResource.php" << 'PHPEOF'
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MissionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
            'paiementEffectue' => $this->paiementEffectue,
            'service_request' => $this->whenLoaded('serviceRequest', fn () => [
                'id' => $this->serviceRequest->id,
                'title' => $this->serviceRequest->title,
            ]),
            'client' => $this->whenLoaded('client', fn () => [
                'id' => $this->client->id,
                'name' => $this->client->name,
            ]),
            'provider_profile' => $this->whenLoaded('providerProfile', fn () => [
                'id' => $this->providerProfile->id,
                'name' => $this->providerProfile->user?->name,
            ]),
            'review' => new ReviewResource($this->whenLoaded('review')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
PHPEOF

mkdir -p "app/Services/Marketplace"
cat > "app/Services/Marketplace/MissionService.php" << 'PHPEOF'
<?php
namespace App\Services\Marketplace;

use App\Events\MissionCompleted;
use App\Models\Mission;
use App\Models\ServiceRequest;

class MissionService
{
    public function start(Mission $mission): void
    {
        abort_unless($mission->status === Mission::STATUS_PENDING, 422, 'Cette mission ne peut pas démarrer.');

        $mission->update(['status' => Mission::STATUS_IN_PROGRESS]);
    }

    public function markAwaitingConfirmation(Mission $mission): void
    {
        abort_unless($mission->status === Mission::STATUS_IN_PROGRESS, 422, "Cette mission n'est pas en cours.");

        $mission->update(['status' => Mission::STATUS_AWAITING_CONFIRMATION]);
    }

    public function confirmCompletion(Mission $mission): void
    {
        abort_unless($mission->status === Mission::STATUS_AWAITING_CONFIRMATION, 422, 'Rien à confirmer pour le moment.');

        $mission->update(['status' => Mission::STATUS_COMPLETED]);
        $mission->serviceRequest->update(['status' => ServiceRequest::STATUS_CLOSED]);

        MissionCompleted::dispatch($mission->fresh());
    }

    public function markPaid(Mission $mission): void
    {
        $mission->update(['paiementEffectue' => true]);
    }

    public function cancel(Mission $mission): void
    {
        abort_if(
            in_array($mission->status, [Mission::STATUS_COMPLETED, Mission::STATUS_CANCELLED]),
            422,
            'Cette mission ne peut plus être annulée.'
        );

        $mission->update(['status' => Mission::STATUS_CANCELLED]);
    }

    /**
     * Statut "disputed" — prévu par le document/prompt mais jamais câblé
     * côté UI jusqu'ici (endpoint API l'exige explicitement : POST .../dispute).
     */
    public function dispute(Mission $mission): void
    {
        abort_if(
            in_array($mission->status, [Mission::STATUS_COMPLETED, Mission::STATUS_CANCELLED]),
            422,
            'Cette mission ne peut plus être contestée.'
        );

        $mission->update(['status' => Mission::STATUS_DISPUTED]);
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/Notification.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notification extends Model
{
    // Types fermés et connus à l'avance — utilisés dans les Listeners
    public const TYPE_NOUVELLE_PROPOSAL = 'nouvelle_proposal';
    public const TYPE_PROPOSAL_ACCEPTEE = 'proposal_acceptee';
    public const TYPE_MISSION_TERMINEE = 'mission_terminee';
    public const TYPE_NOUVEAU_MESSAGE = 'nouveau_message';
    public const TYPE_NOUVEL_AVIS = 'nouvel_avis';

    protected $fillable = [
        'user_id',
        'type',
        'message',
        'lien_associe',
        'lu',
    ];

    protected $casts = [
        'lu' => 'boolean',
    ];

    // --- Relations ---

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/NotificationController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers;

use App\Models\Notification;
use App\Services\Marketplace\NotificationService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class NotificationController extends Controller
{
    public function __construct(private NotificationService $notificationService)
    {
    }

    public function index(Request $request): Response
    {
        $notifications = Notification::where('user_id', $request->user()->id)
            ->latest()
            ->paginate(20);

        return Inertia::render('Notifications/Index', [
            'notifications' => $notifications,
        ]);
    }

    public function markAsRead(Request $request, Notification $notification): RedirectResponse
    {
        abort_unless($notification->user_id === $request->user()->id, 403);

        $this->notificationService->markAsRead($notification);

        return back();
    }

    public function markAllAsRead(Request $request): RedirectResponse
    {
        $this->notificationService->markAllAsRead($request->user());

        return back();
    }
}
PHPEOF

mkdir -p "app/Http/Resources"
cat > "app/Http/Resources/NotificationResource.php" << 'PHPEOF'
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'message' => $this->message,
            'lien_associe' => $this->lien_associe,
            'lu' => $this->lu,
            'created_at' => $this->created_at,
        ];
    }
}
PHPEOF

mkdir -p "app/Services/Marketplace"
cat > "app/Services/Marketplace/NotificationService.php" << 'PHPEOF'
<?php
namespace App\Services\Marketplace;

use App\Models\Notification;
use App\Models\User;

class NotificationService
{
    public function markAsRead(Notification $notification): void
    {
        $notification->update(['lu' => true]);
    }

    public function markAllAsRead(User $user): void
    {
        Notification::where('user_id', $user->id)
            ->where('lu', false)
            ->update(['lu' => true]);
    }
}
PHPEOF

mkdir -p "app/Listeners"
cat > "app/Listeners/NotifyClientMissionCompleted.php" << 'PHPEOF'
<?php
namespace App\Listeners;

use App\Events\MissionCompleted;
use App\Models\Notification;

class NotifyClientMissionCompleted
{
    public function handle(MissionCompleted $event): void
    {
        $mission = $event->mission;

        Notification::create([
            'user_id' => $mission->client_id,
            'type' => Notification::TYPE_MISSION_TERMINEE,
            'message' => 'Votre mission est terminée. Vous pouvez laisser un avis.',
            'lien_associe' => "/missions/{$mission->id}",
        ]);
    }
}
PHPEOF

mkdir -p "app/Listeners"
cat > "app/Listeners/NotifyClientOfNewProposal.php" << 'PHPEOF'
<?php
namespace App\Listeners;

use App\Events\ProposalCreated;
use App\Models\Notification;

class NotifyClientOfNewProposal
{
    public function handle(ProposalCreated $event): void
    {
        $proposal = $event->proposal;
        $serviceRequest = $proposal->serviceRequest;

        Notification::create([
            'user_id' => $serviceRequest->client_id,
            'type' => Notification::TYPE_NOUVELLE_PROPOSAL,
            'message' => "Nouveau devis reçu pour « {$serviceRequest->title} »",
            'lien_associe' => "/service-requests/{$serviceRequest->id}",
        ]);
    }
}
PHPEOF

mkdir -p "app/Listeners"
cat > "app/Listeners/NotifyProviderOfNewReview.php" << 'PHPEOF'
<?php
namespace App\Listeners;

use App\Events\ReviewCreated;
use App\Models\Notification;

class NotifyProviderOfNewReview
{
    public function handle(ReviewCreated $event): void
    {
        $review = $event->review;
        $providerUserId = $review->providerProfile->user_id;

        Notification::create([
            'user_id' => $providerUserId,
            'type' => Notification::TYPE_NOUVEL_AVIS,
            'message' => "Vous avez reçu un avis ({$review->note}/5)",
            'lien_associe' => "/missions/{$review->mission_id}",
        ]);
    }
}
PHPEOF

mkdir -p "app/Listeners"
cat > "app/Listeners/NotifyProviderOfProposalAccepted.php" << 'PHPEOF'
<?php
namespace App\Listeners;

use App\Events\ProposalAccepted;
use App\Models\Notification;

class NotifyProviderOfProposalAccepted
{
    public function handle(ProposalAccepted $event): void
    {
        $proposal = $event->proposal;
        $providerUserId = $proposal->providerProfile->user_id;

        Notification::create([
            'user_id' => $providerUserId,
            'type' => Notification::TYPE_PROPOSAL_ACCEPTEE,
            'message' => "Votre devis a été accepté pour « {$proposal->serviceRequest->title} »",
            'lien_associe' => "/missions/{$proposal->mission->id}",
        ]);
    }
}
PHPEOF

mkdir -p "app/Listeners"
cat > "app/Listeners/NotifyRecipientOfNewMessage.php" << 'PHPEOF'
<?php
namespace App\Listeners;

use App\Events\MessageSent;
use App\Models\Notification;

class NotifyRecipientOfNewMessage
{
    public function handle(MessageSent $event): void
    {
        $message = $event->message;
        $conversation = $message->conversation;

        // Le destinataire est celui des deux qui n'a PAS envoyé le message
        $recipientUserId = $message->sender_id === $conversation->client_id
            ? $conversation->providerProfile->user_id
            : $conversation->client_id;

        Notification::create([
            'user_id' => $recipientUserId,
            'type' => Notification::TYPE_NOUVEAU_MESSAGE,
            'message' => 'Nouveau message reçu',
            'lien_associe' => "/conversations/{$conversation->id}",
        ]);
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/Proposal.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Proposal extends Model
{
    // Statuts figés — section 4.2 du document de référence
    public const STATUS_PENDING = 'pending';
    public const STATUS_ACCEPTED = 'accepted';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_WITHDRAWN = 'withdrawn';

    protected $fillable = [
        'service_request_id',
        'provider_profile_id',
        'montant',
        'delai',
        'description',
        'status',
    ];

    protected $casts = [
        'montant' => 'decimal:2',
    ];

    // --- Relations ---

    public function serviceRequest(): BelongsTo
    {
        return $this->belongsTo(ServiceRequest::class);
    }

    public function providerProfile(): BelongsTo
    {
        return $this->belongsTo(ProviderProfile::class);
    }

    public function mission(): HasOne
    {
        return $this->hasOne(Mission::class);
    }

    // --- Helpers ---

    public function isAccepted(): bool
    {
        return $this->status === self::STATUS_ACCEPTED;
    }
}
PHPEOF

mkdir -p "app/Events"
cat > "app/Events/ProposalAccepted.php" << 'PHPEOF'
<?php
namespace App\Events;

use App\Models\Proposal;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ProposalAccepted
{
    use Dispatchable, SerializesModels;

    public function __construct(public Proposal $proposal)
    {
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/ProposalController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers;

use App\Http\Requests\StoreProposalRequest;
use App\Models\Proposal;
use App\Models\ProviderProfile;
use App\Models\ServiceRequest;
use App\Services\Marketplace\ProposalService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class ProposalController extends Controller
{
    public function __construct(private ProposalService $proposalService)
    {
    }

    public function store(StoreProposalRequest $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        $providerProfile = ProviderProfile::where('user_id', $request->user()->id)->first();
        abort_unless($providerProfile, 422, "Vous n'avez pas encore de profil prestataire.");

        $this->proposalService->submit($serviceRequest, $providerProfile, $request->validated());

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', 'Devis envoyé.');
    }

    public function accept(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $mission = $this->proposalService->accept($proposal);

        return redirect()
            ->route('missions.show', $mission)
            ->with('success', 'Devis accepté, mission créée.');
    }

    public function reject(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $this->proposalService->reject($proposal);

        return back()->with('success', 'Devis refusé.');
    }

    public function withdraw(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('withdraw', $proposal);

        $this->proposalService->withdraw($proposal);

        return back()->with('success', 'Devis retiré.');
    }
}
PHPEOF

mkdir -p "app/Events"
cat > "app/Events/ProposalCreated.php" << 'PHPEOF'
<?php
namespace App\Events;

use App\Models\Proposal;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ProposalCreated
{
    use Dispatchable, SerializesModels;

    public function __construct(public Proposal $proposal)
    {
    }
}
PHPEOF

mkdir -p "app/Policies"
cat > "app/Policies/ProposalPolicy.php" << 'PHPEOF'
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
PHPEOF

mkdir -p "app/Http/Resources"
cat > "app/Http/Resources/ProposalResource.php" << 'PHPEOF'
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProposalResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'montant' => $this->montant,
            'delai' => $this->delai,
            'description' => $this->description,
            'status' => $this->status,
            'service_request_id' => $this->service_request_id,
            'provider_profile' => $this->whenLoaded('providerProfile', fn () => [
                'id' => $this->providerProfile->id,
                'name' => $this->providerProfile->user?->name,
            ]),
            'created_at' => $this->created_at,
        ];
    }
}
PHPEOF

mkdir -p "app/Services/Marketplace"
cat > "app/Services/Marketplace/ProposalService.php" << 'PHPEOF'
<?php
namespace App\Services\Marketplace;

use App\Events\ProposalAccepted;
use App\Events\ProposalCreated;
use App\Models\Mission;
use App\Models\Proposal;
use App\Models\ProviderProfile;
use App\Models\ServiceRequest;
use Illuminate\Support\Facades\DB;

class ProposalService
{
    public function submit(ServiceRequest $serviceRequest, ProviderProfile $providerProfile, array $data): Proposal
    {
        abort_unless($serviceRequest->isOpenToProposals(), 422, "Cette demande n'accepte plus de devis.");

        $proposal = Proposal::create([
            ...$data,
            'service_request_id' => $serviceRequest->id,
            'provider_profile_id' => $providerProfile->id,
            'status' => Proposal::STATUS_PENDING,
        ]);

        if ($serviceRequest->status === ServiceRequest::STATUS_PUBLISHED) {
            $serviceRequest->update(['status' => ServiceRequest::STATUS_MATCHED]);
        }

        ProposalCreated::dispatch($proposal);

        return $proposal;
    }

    /**
     * Accepte un devis : rejette automatiquement les autres pending,
     * passe la demande à "assigned", crée la Mission — le tout en
     * transaction pour ne jamais laisser un état intermédiaire incohérent.
     */
    public function accept(Proposal $proposal): Mission
    {
        abort_unless($proposal->status === Proposal::STATUS_PENDING, 422, "Ce devis n'est plus disponible.");

        $serviceRequest = $proposal->serviceRequest;
        $mission = null;

        DB::transaction(function () use ($proposal, $serviceRequest, &$mission) {
            $proposal->update(['status' => Proposal::STATUS_ACCEPTED]);

            $serviceRequest->proposals()
                ->where('id', '!=', $proposal->id)
                ->where('status', Proposal::STATUS_PENDING)
                ->update(['status' => Proposal::STATUS_REJECTED]);

            $serviceRequest->update(['status' => ServiceRequest::STATUS_ASSIGNED]);

            $mission = Mission::create([
                'service_request_id' => $serviceRequest->id,
                'proposal_id' => $proposal->id,
                'client_id' => $serviceRequest->client_id,
                'provider_profile_id' => $proposal->provider_profile_id,
                'status' => Mission::STATUS_PENDING,
                'paiementEffectue' => false,
            ]);
        });

        ProposalAccepted::dispatch($proposal->fresh());

        return $mission;
    }

    public function reject(Proposal $proposal): void
    {
        abort_unless($proposal->status === Proposal::STATUS_PENDING, 422, "Ce devis n'est plus disponible.");

        $proposal->update(['status' => Proposal::STATUS_REJECTED]);
    }

    public function withdraw(Proposal $proposal): void
    {
        abort_unless($proposal->status === Proposal::STATUS_PENDING, 422, "Ce devis n'est plus disponible.");

        $proposal->update(['status' => Proposal::STATUS_WITHDRAWN]);
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/ProviderProfile.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class ProviderProfile extends Model
{
    protected $fillable = [
        'user_id',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function services(): BelongsToMany
    {
        return $this->belongsToMany(Service::class, 'provider_services', 'provider_profile_id', 'service_id');
    }

    public function zones(): BelongsToMany
    {
        return $this->belongsToMany(Zone::class, 'provider_zones', 'provider_profile_id', 'zone_id');
    }
}
PHPEOF

mkdir -p "database/factories"
cat > "database/factories/ProviderProfileFactory.php" << 'PHPEOF'
<?php
namespace Database\Factories;

use App\Models\ProviderProfile;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ProviderProfileFactory extends Factory
{
    protected $model = ProviderProfile::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory()->state(['estPrestataire' => true]),
        ];
    }
}
PHPEOF

mkdir -p "app/Http/Resources"
cat > "app/Http/Resources/ProviderProfileResource.php" << 'PHPEOF'
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProviderProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->user?->name,
            'services' => $this->whenLoaded('services', fn () => $this->services->map(fn ($s) => [
                'id' => $s->id,
                'name' => $s->name,
            ])),
            'zones' => $this->whenLoaded('zones', fn () => $this->zones->map(fn ($z) => [
                'id' => $z->id,
                'name' => $z->name,
            ])),
        ];
    }
}
PHPEOF

mkdir -p "database/seeders"
cat > "database/seeders/ReferenceDataSeeder.php" << 'PHPEOF'
<?php
namespace Database\Seeders;

use App\Models\ProviderProfile;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use App\Models\Zone;
use Illuminate\Database\Seeder;

class ReferenceDataSeeder extends Seeder
{
    public function run(): void
    {
        $categoriesEtServices = [
            'Carrelage' => ['Pose de carrelage', 'Faïence murale', 'Réparation de carreaux'],
            'Plomberie' => ['Installation sanitaire', 'Réparation de fuite', 'Débouchage'],
            'Électricité' => ['Installation électrique', 'Dépannage', 'Mise aux normes'],
            'Peinture' => ['Peinture intérieure', 'Peinture extérieure'],
            'Menuiserie' => ['Fabrication de meubles', 'Pose de portes/fenêtres'],
        ];

        $services = collect();

        foreach ($categoriesEtServices as $categoryName => $serviceNames) {
            $category = ServiceCategory::firstOrCreate(['name' => $categoryName]);

            foreach ($serviceNames as $serviceName) {
                $services->push(
                    Service::firstOrCreate(['category_id' => $category->id, 'name' => $serviceName])
                );
            }
        }

        $zones = collect(['Tankpè', 'Calavi', 'Godomey', 'Cococodji', 'Cotonou'])
            ->map(fn ($name) => Zone::firstOrCreate(['name' => $name]));

        // Quelques prestataires de test, avec services + zones déclarés
        $providersData = [
            ['name' => 'Alain K. (Carreleur)', 'services' => ['Pose de carrelage', 'Faïence murale'], 'zones' => ['Tankpè', 'Calavi']],
            ['name' => 'Sophie M. (Électricienne)', 'services' => ['Installation électrique', 'Dépannage'], 'zones' => ['Tankpè', 'Cotonou']],
            ['name' => 'Jean D. (Plombier)', 'services' => ['Installation sanitaire', 'Réparation de fuite'], 'zones' => ['Godomey']],
        ];

        foreach ($providersData as $data) {
            $user = User::firstOrCreate(
                ['email' => \Illuminate\Support\Str::slug($data['name']).'@service229.test'],
                ['name' => $data['name'], 'password' => bcrypt('password'), 'estClient' => true, 'estPrestataire' => true]
            );

            $providerProfile = ProviderProfile::firstOrCreate(['user_id' => $user->id]);

            $serviceIds = $services->whereIn('name', $data['services'])->pluck('id');
            $providerProfile->services()->syncWithoutDetaching($serviceIds);

            $zoneIds = $zones->whereIn('name', $data['zones'])->pluck('id');
            $providerProfile->zones()->syncWithoutDetaching($zoneIds);
        }

        $this->command->info('Données de référence créées : 5 catégories, ~12 services, 5 zones, 3 prestataires.');
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/Review.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Review extends Model
{
    protected $fillable = [
        'mission_id',
        'client_id',
        'provider_profile_id',
        'note',
        'commentaire',
    ];

    protected $casts = [
        'note' => 'integer',
    ];

    // --- Relations ---

    public function mission(): BelongsTo
    {
        return $this->belongsTo(Mission::class);
    }

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function providerProfile(): BelongsTo
    {
        return $this->belongsTo(ProviderProfile::class);
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/ReviewController.php" << 'PHPEOF'
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
PHPEOF

mkdir -p "app/Events"
cat > "app/Events/ReviewCreated.php" << 'PHPEOF'
<?php
namespace App\Events;

use App\Models\Review;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ReviewCreated
{
    use Dispatchable, SerializesModels;

    public function __construct(public Review $review)
    {
    }
}
PHPEOF

mkdir -p "app/Policies"
cat > "app/Policies/ReviewPolicy.php" << 'PHPEOF'
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
PHPEOF

mkdir -p "app/Http/Resources"
cat > "app/Http/Resources/ReviewResource.php" << 'PHPEOF'
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReviewResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        if (! $this->resource) {
            return [];
        }

        return [
            'id' => $this->id,
            'note' => $this->note,
            'commentaire' => $this->commentaire,
            'mission_id' => $this->mission_id,
            'created_at' => $this->created_at,
        ];
    }
}
PHPEOF

mkdir -p "app/Services/Marketplace"
cat > "app/Services/Marketplace/ReviewService.php" << 'PHPEOF'
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
PHPEOF

mkdir -p "database/seeders"
cat > "database/seeders/ScenarioCarreleurTankpeSeeder.php" << 'PHPEOF'
<?php
namespace Database\Seeders;

use App\Models\Proposal;
use App\Models\ProviderProfile;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Models\Zone;
use Illuminate\Database\Seeder;

class ScenarioCarreleurTankpeSeeder extends Seeder
{
    public function run(): void
    {
        $carrelage = ServiceCategory::firstOrCreate(['name' => 'Carrelage']);
        $tankpe = Zone::firstOrCreate(['name' => 'Tankpè']);

        $client = User::factory()->create([
            'name' => 'Amina (Cliente test)',
            'estClient' => true,
            'estPrestataire' => false,
        ]);

        $prestataireUser = User::factory()->create([
            'name' => 'Alain K. (Carreleur test)',
            'estClient' => true,
            'estPrestataire' => true,
        ]);

        $providerProfile = ProviderProfile::create([
            'user_id' => $prestataireUser->id,
        ]);

        // 1. Le client publie une demande ouverte (Mode 2)
        $serviceRequest = ServiceRequest::create([
            'client_id' => $client->id,
            'service_category_id' => $carrelage->id,
            'zone_id' => $tankpe->id,
            'title' => 'Pose de carreaux dans mon salon',
            'description' => "Je souhaite poser du carrelage dans un salon d'environ 25 m².",
            'budget_estime' => 60000,
            'date_intervention' => now()->addWeek(),
            'status' => ServiceRequest::STATUS_PUBLISHED,
        ]);

        // 2. Le prestataire envoie un devis
        $proposal = Proposal::create([
            'service_request_id' => $serviceRequest->id,
            'provider_profile_id' => $providerProfile->id,
            'montant' => 55000,
            'delai' => '3 jours',
            'description' => 'Pose complète avec finitions soignées, matériel inclus.',
            'status' => Proposal::STATUS_PENDING,
        ]);

        $serviceRequest->update(['status' => ServiceRequest::STATUS_MATCHED]);

        $this->command->info("Scénario créé : ServiceRequest #{$serviceRequest->id}, Proposal #{$proposal->id}");
        $this->command->info("Client : {$client->email} | Prestataire : {$prestataireUser->email}");
        $this->command->info('Mot de passe par défaut (UserFactory) : password');
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/SearchController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers;

use App\Models\ServiceCategory;
use App\Models\Zone;
use App\Services\Marketplace\SearchService;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class SearchController extends Controller
{
    public function __construct(private SearchService $searchService)
    {
    }

    public function home(): Response
    {
        return Inertia::render('Home', [
            'serviceCategories' => ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => Zone::orderBy('name')->get(['id', 'name']),
        ]);
    }

    public function index(Request $request): Response
    {
        $validated = $request->validate([
            'service_category_id' => ['nullable', 'exists:service_categories,id'],
            'zone_id' => ['nullable', 'exists:zones,id'],
        ]);

        $providers = $this->searchService->searchProviders(
            $validated['service_category_id'] ?? null,
            $validated['zone_id'] ?? null,
        );

        return Inertia::render('Search/Results', [
            'providers' => $providers,
            'filters' => $validated,
            'serviceCategories' => ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => Zone::orderBy('name')->get(['id', 'name']),
        ]);
    }
}
PHPEOF

mkdir -p "app/Services/Marketplace"
cat > "app/Services/Marketplace/SearchService.php" << 'PHPEOF'
<?php
namespace App\Services\Marketplace;

use App\Models\ProviderProfile;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

class SearchService
{
    /**
     * Recherche publique de prestataires par catégorie + zone.
     * Utilisé par SearchController (Inertia) et Api\V1\SearchController.
     */
    public function searchProviders(?int $serviceCategoryId, ?int $zoneId): Collection
    {
        return ProviderProfile::query()
            ->with(['user', 'services.category', 'zones'])
            ->when(
                $serviceCategoryId,
                fn ($q, $categoryId) => $q->whereHas(
                    'services',
                    fn ($sq) => $sq->where('category_id', $categoryId)
                )
            )
            ->when(
                $zoneId,
                fn ($q, $zoneId) => $q->whereHas('zones', fn ($zq) => $zq->where('zones.id', $zoneId))
            )
            ->get();
    }

    /**
     * "Demandes disponibles" pour un prestataire : demandes publiées qui
     * correspondent à ses services/zones déclarés, hors celles où il a
     * déjà répondu.
     */
    public function availableRequestsForProvider(User $user): LengthAwarePaginator
    {
        $providerProfile = ProviderProfile::where('user_id', $user->id)->first();

        $serviceIds = $providerProfile?->services()->pluck('services.id') ?? collect();
        $zoneIds = $providerProfile?->zones()->pluck('zones.id') ?? collect();

        return ServiceRequest::query()
            ->where('status', ServiceRequest::STATUS_PUBLISHED)
            ->when($serviceIds->isNotEmpty(), function ($q) use ($serviceIds) {
                $q->whereHas(
                    'serviceCategory.services',
                    fn ($sq) => $sq->whereIn('services.id', $serviceIds)
                );
            })
            ->when($zoneIds->isNotEmpty(), fn ($q) => $q->whereIn('zone_id', $zoneIds))
            ->whereDoesntHave(
                'proposals',
                fn ($q) => $q->where('provider_profile_id', $providerProfile?->id)
            )
            ->with(['serviceCategory', 'zone', 'client'])
            ->latest()
            ->paginate(10);
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/Service.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Service extends Model
{
    protected $fillable = [
        'category_id',
        'name',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class, 'category_id');
    }

    public function providers(): BelongsToMany
    {
        return $this->belongsToMany(ProviderProfile::class, 'provider_services', 'service_id', 'provider_profile_id');
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/ServiceCategory.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ServiceCategory extends Model
{
    protected $fillable = ['name'];

    public function services(): HasMany
    {
        return $this->hasMany(Service::class, 'category_id');
    }
}
PHPEOF

mkdir -p "database/factories"
cat > "database/factories/ServiceCategoryFactory.php" << 'PHPEOF'
<?php
namespace Database\Factories;

use App\Models\ServiceCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

class ServiceCategoryFactory extends Factory
{
    protected $model = ServiceCategory::class;

    public function definition(): array
    {
        return [
            'name' => fake()->unique()->randomElement([
                'Carrelage', 'Plomberie', 'Électricité', 'Peinture', 'Menuiserie',
            ]),
        ];
    }
}
PHPEOF

mkdir -p "database/factories"
cat > "database/factories/ServiceFactory.php" << 'PHPEOF'
<?php
namespace Database\Factories;

use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

class ServiceFactory extends Factory
{
    protected $model = Service::class;

    public function definition(): array
    {
        return [
            'category_id' => ServiceCategory::factory(),
            'name' => fake()->randomElement([
                'Pose de carrelage', 'Faïence murale', 'Réparation de carreaux',
            ]),
        ];
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/ServiceRequest.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ServiceRequest extends Model
{
    // Statuts figés — section 4.1 du document de référence
    public const STATUS_DRAFT = 'draft';
    public const STATUS_PUBLISHED = 'published';
    public const STATUS_MATCHED = 'matched';
    public const STATUS_ASSIGNED = 'assigned';
    public const STATUS_CANCELLED = 'cancelled';
    public const STATUS_EXPIRED = 'expired';
    public const STATUS_CLOSED = 'closed';

    protected $fillable = [
        'client_id',
        'service_category_id',
        'zone_id',
        'provider_profile_id',
        'title',
        'description',
        'budget_estime',
        'date_intervention',
        'status',
    ];

    protected $casts = [
        'budget_estime' => 'decimal:2',
        'date_intervention' => 'date',
    ];

    // --- Relations ---

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function serviceCategory(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class);
    }

    public function zone(): BelongsTo
    {
        return $this->belongsTo(Zone::class);
    }

    // Renseigné uniquement en Mode 1 (contact direct)
    public function providerProfile(): BelongsTo
    {
        return $this->belongsTo(ProviderProfile::class);
    }

    public function proposals(): HasMany
    {
        return $this->hasMany(Proposal::class);
    }

    public function mission(): HasOne
    {
        return $this->hasOne(Mission::class);
    }

    public function conversation(): HasOne
    {
        return $this->hasOne(Conversation::class);
    }

    public function photos(): HasMany
    {
        return $this->hasMany(ServiceRequestPhoto::class);
    }

    // --- Helpers ---

    public function isOpenToProposals(): bool
    {
        return $this->status === self::STATUS_PUBLISHED;
    }
}
PHPEOF

mkdir -p "app/Http/Controllers"
cat > "app/Http/Controllers/ServiceRequestController.php" << 'PHPEOF'
<?php
namespace App\Http\Controllers;

use App\Http\Requests\StoreServiceRequestRequest;
use App\Models\ServiceRequest;
use App\Services\Marketplace\ServiceRequestService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ServiceRequestController extends Controller
{
    public function __construct(private ServiceRequestService $serviceRequestService)
    {
    }

    public function index(Request $request): Response
    {
        $serviceRequests = ServiceRequest::query()
            ->where('client_id', $request->user()->id)
            ->with(['serviceCategory', 'zone', 'providerProfile', 'proposals'])
            ->latest()
            ->paginate(10);

        return Inertia::render('ServiceRequests/Index', [
            'serviceRequests' => $serviceRequests,
        ]);
    }

    public function create(Request $request): Response
    {
        return Inertia::render('ServiceRequests/Create', [
            'serviceCategories' => \App\Models\ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => \App\Models\Zone::orderBy('name')->get(['id', 'name']),
            'preselectedProviderProfileId' => $request->integer('provider_profile_id') ?: null,
        ]);
    }

    public function show(Request $request, ServiceRequest $serviceRequest): Response
    {
        $this->authorize('view', $serviceRequest);

        $serviceRequest->load([
            'serviceCategory',
            'zone',
            'providerProfile',
            'proposals.providerProfile.user',
            'mission',
            'conversation.messages',
            'photos',
        ]);

        return Inertia::render('ServiceRequests/Show', [
            'serviceRequest' => $serviceRequest,
        ]);
    }

    public function store(StoreServiceRequestRequest $request): RedirectResponse
    {
        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $serviceRequest = $this->serviceRequestService->create(
            $request->user(),
            $validated,
            $photos,
            $request->boolean('as_draft')
        );

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', 'Demande créée avec succès.');
    }

    public function edit(Request $request, ServiceRequest $serviceRequest): Response
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être modifié.');

        $serviceRequest->load('photos');

        return Inertia::render('ServiceRequests/Edit', [
            'serviceRequest' => $serviceRequest,
            'serviceCategories' => \App\Models\ServiceCategory::orderBy('name')->get(['id', 'name']),
            'zones' => \App\Models\Zone::orderBy('name')->get(['id', 'name']),
        ]);
    }

    public function update(StoreServiceRequestRequest $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être modifié.');

        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $this->serviceRequestService->update(
            $serviceRequest,
            $validated,
            $photos,
            $request->boolean('as_draft')
        );

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', $request->boolean('as_draft') ? 'Brouillon mis à jour.' : 'Demande publiée.');
    }

    public function destroy(Request $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        abort_unless($serviceRequest->client_id === $request->user()->id, 403);
        abort_unless($serviceRequest->status === ServiceRequest::STATUS_DRAFT, 422, 'Seul un brouillon peut être supprimé.');

        $this->serviceRequestService->delete($serviceRequest);

        return redirect()
            ->route('service-requests.index')
            ->with('success', 'Brouillon supprimé.');
    }

    public function cancel(Request $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        $this->authorize('cancel', $serviceRequest);

        $this->serviceRequestService->cancel($serviceRequest);

        return redirect()
            ->route('service-requests.index')
            ->with('success', 'Demande annulée.');
    }

    public function browse(Request $request): Response
    {
        $user = $request->user();
        abort_unless($user->estPrestataire, 403, 'Cette page est réservée aux prestataires.');

        $serviceRequests = app(\App\Services\Marketplace\SearchService::class)
            ->availableRequestsForProvider($user);

        return Inertia::render('ServiceRequests/Browse', [
            'serviceRequests' => $serviceRequests,
        ]);
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/ServiceRequestPhoto.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ServiceRequestPhoto extends Model
{
    protected $fillable = [
        'service_request_id',
        'chemin_fichier',
    ];

    public function serviceRequest(): BelongsTo
    {
        return $this->belongsTo(ServiceRequest::class);
    }

    // URL publique complète, utile côté Vue (ex: <img :src="photo.url">)
    public function getUrlAttribute(): string
    {
        return \Storage::disk('public')->url($this->chemin_fichier);
    }
}
PHPEOF

mkdir -p "app/Policies"
cat > "app/Policies/ServiceRequestPolicy.php" << 'PHPEOF'
<?php
namespace App\Policies;

use App\Models\ServiceRequest;
use App\Models\User;

class ServiceRequestPolicy
{
    public function view(User $user, ServiceRequest $serviceRequest): bool
    {
        // Le client propriétaire peut toujours voir sa demande
        if ($serviceRequest->client_id === $user->id) {
            return true;
        }

        // Un prestataire peut voir le détail d'une demande PUBLIÉE (pour
        // pouvoir y répondre) ou de celle sur laquelle il a déjà un devis
        if ($user->estPrestataire) {
            if ($serviceRequest->status === ServiceRequest::STATUS_PUBLISHED) {
                return true;
            }

            $providerProfile = \App\Models\ProviderProfile::where('user_id', $user->id)->first();

            return $providerProfile && $serviceRequest->proposals()
                ->where('provider_profile_id', $providerProfile->id)
                ->exists();
        }

        return false;
    }

    public function cancel(User $user, ServiceRequest $serviceRequest): bool
    {
        return $serviceRequest->client_id === $user->id
            && $serviceRequest->status !== ServiceRequest::STATUS_CLOSED;
    }
}
PHPEOF

mkdir -p "app/Http/Resources"
cat > "app/Http/Resources/ServiceRequestResource.php" << 'PHPEOF'
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status,
            'budget_estime' => $this->budget_estime,
            'date_intervention' => $this->date_intervention,
            'client_id' => $this->client_id,
            'service_category' => $this->whenLoaded('serviceCategory', fn () => [
                'id' => $this->serviceCategory->id,
                'name' => $this->serviceCategory->name,
            ]),
            'zone' => $this->whenLoaded('zone', fn () => [
                'id' => $this->zone->id,
                'name' => $this->zone->name,
            ]),
            'photos' => $this->whenLoaded('photos', fn () => $this->photos->map(fn ($p) => [
                'id' => $p->id,
                'url' => $p->url,
            ])),
            'proposals' => ProposalResource::collection($this->whenLoaded('proposals')),
            'proposals_count' => $this->whenCounted('proposals'),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
PHPEOF

mkdir -p "app/Services/Marketplace"
cat > "app/Services/Marketplace/ServiceRequestService.php" << 'PHPEOF'
<?php
namespace App\Services\Marketplace;

use App\Models\ServiceRequest;
use App\Models\ServiceRequestPhoto;
use App\Models\User;
use Illuminate\Http\UploadedFile;

class ServiceRequestService
{
    /**
     * Crée une demande — couvre les deux modes (contact direct / besoin
     * ouvert) et les deux statuts (brouillon / publiée).
     *
     * @param  UploadedFile[]  $photos
     */
    public function create(User $client, array $data, array $photos, bool $asDraft): ServiceRequest
    {
        $isDirectContact = ! empty($data['provider_profile_id']);

        $status = match (true) {
            $isDirectContact => ServiceRequest::STATUS_ASSIGNED,
            $asDraft => ServiceRequest::STATUS_DRAFT,
            default => ServiceRequest::STATUS_PUBLISHED,
        };

        $serviceRequest = ServiceRequest::create([
            ...$data,
            'client_id' => $client->id,
            'status' => $status,
        ]);

        $this->attachPhotos($serviceRequest, $photos);

        return $serviceRequest;
    }

    /**
     * Met à jour un brouillon (seul statut modifiable librement).
     *
     * @param  UploadedFile[]  $photos
     */
    public function update(ServiceRequest $serviceRequest, array $data, array $photos, bool $asDraft): ServiceRequest
    {
        $status = $asDraft ? ServiceRequest::STATUS_DRAFT : ServiceRequest::STATUS_PUBLISHED;

        $serviceRequest->update([...$data, 'status' => $status]);

        $this->attachPhotos($serviceRequest, $photos);

        return $serviceRequest->fresh();
    }

    /**
     * Suppression définitive — réservée aux brouillons (voir Policy).
     */
    public function delete(ServiceRequest $serviceRequest): void
    {
        foreach ($serviceRequest->photos as $photo) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($photo->chemin_fichier);
        }

        $serviceRequest->delete();
    }

    public function cancel(ServiceRequest $serviceRequest): void
    {
        $serviceRequest->update(['status' => ServiceRequest::STATUS_CANCELLED]);
    }

    /**
     * @param  UploadedFile[]  $photos
     */
    private function attachPhotos(ServiceRequest $serviceRequest, array $photos): void
    {
        foreach ($photos as $photo) {
            $path = $photo->store('service-requests', 'public');

            ServiceRequestPhoto::create([
                'service_request_id' => $serviceRequest->id,
                'chemin_fichier' => $path,
            ]);
        }
    }
}
PHPEOF

mkdir -p "app/Http/Requests"
cat > "app/Http/Requests/StoreMessageRequest.php" << 'PHPEOF'
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // vérifié au niveau du controller (participant à la conversation)
    }

    public function rules(): array
    {
        return [
            'content' => ['required', 'string', 'max:2000'],
        ];
    }
}
PHPEOF

mkdir -p "app/Http/Requests"
cat > "app/Http/Requests/StoreProposalRequest.php" << 'PHPEOF'
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreProposalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // vérifié au niveau du controller (isOpenToProposals)
    }

    public function rules(): array
    {
        return [
            'montant' => ['required', 'numeric', 'min:0'],
            'delai' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
        ];
    }
}
PHPEOF

mkdir -p "app/Http/Requests"
cat > "app/Http/Requests/StoreReviewRequest.php" << 'PHPEOF'
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreReviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // vérifié au niveau du controller (client + mission completed)
    }

    public function rules(): array
    {
        return [
            'note' => ['required', 'integer', 'min:1', 'max:5'],
            'commentaire' => ['nullable', 'string'],
        ];
    }
}
PHPEOF

mkdir -p "app/Http/Requests"
cat > "app/Http/Requests/StoreServiceRequestRequest.php" << 'PHPEOF'
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreServiceRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // tout utilisateur authentifié peut créer une demande
    }

    public function rules(): array
    {
        return [
            'service_category_id' => ['required', 'exists:service_categories,id'],
            'zone_id' => ['required', 'exists:zones,id'],
            'provider_profile_id' => ['nullable', 'exists:provider_profiles,id'],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'budget_estime' => ['nullable', 'numeric', 'min:0'],
            'date_intervention' => ['nullable', 'date', 'after_or_equal:today'],
            'photos' => ['nullable', 'array', 'max:5'],
            'photos.*' => ['image', 'mimes:jpg,jpeg,png', 'max:5120'], // 5 Mo, cohérent avec la maquette
        ];
    }
}
PHPEOF

mkdir -p "app/Models"
cat > "app/Models/Zone.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Zone extends Model
{
    protected $fillable = ['name'];
}
PHPEOF

mkdir -p "database/factories"
cat > "database/factories/ZoneFactory.php" << 'PHPEOF'
<?php
namespace Database\Factories;

use App\Models\Zone;
use Illuminate\Database\Eloquent\Factories\Factory;

class ZoneFactory extends Factory
{
    protected $model = Zone::class;

    public function definition(): array
    {
        return [
            'name' => fake()->unique()->randomElement([
                'Tankpè', 'Calavi', 'Godomey', 'Cococodji', 'Cotonou',
            ]),
        ];
    }
}
PHPEOF

mkdir -p "routes"
cat > "routes/api_abed.php" << 'PHPEOF'
<?php
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
PHPEOF

mkdir -p "bootstrap"
cat > "bootstrap/app.php" << 'PHPEOF'
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->web(append: [
            \App\Http\Middleware\HandleInertiaRequests::class,
            \Illuminate\Http\Middleware\AddLinkHeadersForPreloadedAssets::class,
        ]);


        $middleware->alias([
            'admin' => \App\Http\Middleware\EnsureAdmin::class,
        ]);

    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
PHPEOF

echo "== Frontend (Vue.js + Tailwind) =="

mkdir -p "resources/js/Layouts"
cat > "resources/js/Layouts/AppLayout.vue" << 'VUEEOF'
<script setup>
import { computed, ref } from 'vue';
import { Head, Link, usePage } from '@inertiajs/vue3';

defineProps({
    title: { type: String, default: '' },
});

const page = usePage();
const user = page.props.auth?.user;

const navItems = computed(() => {
    const items = [
        { label: 'Tableau de bord', route: 'dashboard' },
        { label: 'Nouvelle demande', route: 'service-requests.create' },
        { label: 'Mes demandes', route: 'service-requests.index' },
        { label: 'Mes missions', route: 'missions.index' },
        { label: 'Messagerie', route: 'conversations.index' },
        { label: 'Notifications', route: 'notifications.index' },
    ];

    if (user?.estPrestataire) {
        items.splice(3, 0, { label: 'Demandes disponibles', route: 'service-requests.browse' });
    }

    return items;
});

const sidebarOpen = ref(false);
</script>

<template>
    <Head :title="title" />

    <div class="min-h-screen bg-gray-50">
        <!-- Barre du haut (mobile) -->
        <div class="flex items-center justify-between border-b border-gray-200 bg-white px-4 py-3 md:hidden">
            <Link :href="route('dashboard')" class="text-lg font-bold text-brand">Service229</Link>
            <button @click="sidebarOpen = !sidebarOpen" class="text-gray-600" aria-label="Ouvrir le menu">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
            </button>
        </div>

        <div class="flex">
            <!-- Sidebar -->
            <aside
                class="fixed inset-y-0 left-0 z-30 w-64 transform border-r border-gray-200 bg-white transition-transform md:static md:translate-x-0"
                :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full'"
            >
                <div class="hidden border-b border-gray-100 p-6 md:block">
                    <Link :href="route('dashboard')" class="text-xl font-bold text-brand">Service229</Link>
                </div>

                <nav class="flex flex-col gap-1 p-4">
                    <Link
                        v-for="item in navItems"
                        :key="item.route"
                        :href="route(item.route)"
                        class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-gray-700 transition hover:bg-brand-light hover:text-brand"
                        :class="{ 'bg-brand-light text-brand': route().current(item.route + '*') }"
                    >
                        {{ item.label }}
                    </Link>
                </nav>

                <div class="absolute bottom-0 w-64 border-t border-gray-100 p-4">
                    <div class="mb-3 flex items-center gap-3">
                        <div class="flex h-9 w-9 items-center justify-center rounded-full bg-brand-light text-sm font-semibold text-brand">
                            {{ user?.name?.charAt(0) }}
                        </div>
                        <div class="min-w-0">
                            <p class="truncate text-sm font-medium text-gray-900">{{ user?.name }}</p>
                        </div>
                    </div>
                    <Link
                        :href="route('logout')"
                        method="post"
                        as="button"
                        class="w-full rounded-lg border border-gray-200 px-3 py-2 text-left text-sm text-gray-600 hover:bg-gray-50"
                    >
                        Se déconnecter
                    </Link>
                </div>
            </aside>

            <!-- Contenu -->
            <main class="min-h-screen flex-1 p-6 md:p-10">
                <slot />
            </main>
        </div>
    </div>
</template>
VUEEOF

mkdir -p "resources/js/Pages"
cat > "resources/js/Pages/Dashboard.vue" << 'VUEEOF'
<script setup>
import { Link, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    stats: {
        type: Object,
        default: () => ({ demandes_actives: 0, propositions_recues: 0, missions_en_cours: 0, missions_terminees: 0 }),
    },
    recentServiceRequests: { type: Array, default: () => [] },
});

const page = usePage();
const userName = computed(() => page.props.auth?.user?.name ?? '');

const statCards = computed(() => [
    { label: 'Demandes actives', value: props.stats.demandes_actives, icon: '📋' },
    { label: 'Propositions reçues', value: props.stats.propositions_recues, icon: '📩' },
    { label: 'Mission en cours', value: props.stats.missions_en_cours, icon: '💼', highlight: true },
    { label: 'Missions terminées', value: props.stats.missions_terminees, icon: '✅' },
]);

const statusLabels = {
    draft: 'Brouillon',
    published: 'En attente de devis',
    matched: 'Propositions reçues',
    assigned: 'Artisan assigné',
    cancelled: 'Annulée',
    expired: 'Expirée',
    closed: 'Terminée',
};
</script>

<template>
    <AppLayout title="Tableau de bord">
        <h1 class="text-2xl font-bold text-gray-900">Bonjour {{ userName }} 👋</h1>
        <p class="mt-1 text-sm text-gray-500">Voici un aperçu de vos activités récentes.</p>

        <div class="mt-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
            <div
                v-for="card in statCards"
                :key="card.label"
                class="rounded-xl p-5"
                :class="card.highlight ? 'bg-brand text-white' : 'border border-gray-200 bg-white'"
            >
                <span class="text-2xl">{{ card.icon }}</span>
                <p class="mt-3 text-2xl font-bold">{{ card.value }}</p>
                <p class="text-sm" :class="card.highlight ? 'text-white/80' : 'text-gray-500'">{{ card.label }}</p>
            </div>
        </div>

        <div class="mt-10 flex items-center justify-between">
            <h2 class="text-lg font-semibold text-gray-900">Mes demandes récentes</h2>
            <Link :href="route('service-requests.index')" class="text-sm font-medium text-brand hover:underline">
                Voir tout
            </Link>
        </div>

        <div v-if="recentServiceRequests.length === 0" class="mt-4 rounded-xl border border-dashed border-gray-300 p-8 text-center">
            <p class="text-gray-500">Aucune demande pour le moment.</p>
            <Link :href="route('service-requests.create')" class="mt-2 inline-block font-semibold text-brand hover:underline">
                Publier votre première demande
            </Link>
        </div>

        <div v-else class="mt-4 space-y-3">
            <Link
                v-for="sr in recentServiceRequests"
                :key="sr.id"
                :href="sr.status === 'draft' ? route('service-requests.edit', sr.id) : route('service-requests.show', sr.id)"
                class="flex items-center justify-between rounded-xl border border-gray-200 bg-white p-4 hover:border-brand"
            >
                <div>
                    <p class="font-semibold text-gray-900">{{ sr.title }}</p>
                    <p class="text-sm text-gray-500">{{ sr.service_category?.name }} · {{ sr.zone?.name }}</p>
                </div>
                <span class="rounded-full bg-gray-100 px-3 py-1 text-xs font-medium text-gray-600">
                    {{ statusLabels[sr.status] ?? sr.status }}
                </span>
            </Link>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages"
cat > "resources/js/Pages/Home.vue" << 'VUEEOF'
<script setup>
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import { ref } from 'vue';

const props = defineProps({
    serviceCategories: { type: Array, default: () => [] },
    zones: { type: Array, default: () => [] },
});

const page = usePage();
const isAuthenticated = !!page.props.auth?.user;

const serviceCategoryId = ref('');
const zoneId = ref('');

function search() {
    router.get(route('search.index'), {
        service_category_id: serviceCategoryId.value || undefined,
        zone_id: zoneId.value || undefined,
    });
}
</script>

<template>
    <Head title="Accueil" />

    <div class="min-h-screen bg-gray-50">
        <!-- Barre de navigation publique -->
        <header class="border-b border-gray-200 bg-white">
            <div class="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
                <Link href="/" class="text-lg font-bold text-brand">Service229</Link>
                <div v-if="!isAuthenticated" class="flex items-center gap-3">
                    <Link :href="route('login')" class="text-sm font-medium text-gray-600 hover:text-brand">Connexion</Link>
                    <Link
                        :href="route('register')"
                        class="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
                    >
                        Sign Up
                    </Link>
                </div>
                <Link v-else :href="route('dashboard')" class="text-sm font-medium text-brand hover:underline">
                    Mon tableau de bord
                </Link>
            </div>
        </header>

        <!-- Hero -->
        <section class="bg-gray-50 px-6 py-16 text-center">
            <h1 class="mx-auto max-w-2xl text-3xl font-bold text-gray-900 sm:text-4xl">
                Trouvez le bon professionnel près de chez vous
            </h1>
            <p class="mx-auto mt-3 max-w-xl text-gray-500">
                Trouvez rapidement un artisan ou prestataire de confiance selon votre besoin et votre quartier au Bénin.
            </p>

            <div class="mx-auto mt-8 flex max-w-2xl flex-col gap-3 rounded-2xl bg-white p-4 shadow-sm sm:flex-row sm:items-center">
                <select
                    v-model="serviceCategoryId"
                    class="flex-1 rounded-lg border-gray-200 text-sm focus:border-brand focus:ring-brand"
                >
                    <option value="">Quel service recherchez-vous ?</option>
                    <option v-for="category in serviceCategories" :key="category.id" :value="category.id">
                        {{ category.name }}
                    </option>
                </select>
                <select
                    v-model="zoneId"
                    class="flex-1 rounded-lg border-gray-200 text-sm focus:border-brand focus:ring-brand"
                >
                    <option value="">Où ?</option>
                    <option v-for="zone in zones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
                </select>
                <button
                    class="rounded-lg bg-brand px-6 py-2.5 text-sm font-semibold text-white hover:bg-brand-dark"
                    @click="search"
                >
                    Rechercher
                </button>
                <Link
                    v-if="isAuthenticated"
                    :href="route('service-requests.create')"
                    class="rounded-lg border border-brand px-6 py-2.5 text-center text-sm font-semibold text-brand hover:bg-brand-light"
                >
                    Publier une demande
                </Link>
            </div>
        </section>

        <!-- Catégories populaires -->
        <section class="mx-auto max-w-6xl px-6 py-12">
            <h2 class="text-xl font-bold text-gray-900">Catégories populaires</h2>
            <p class="mt-1 text-sm text-gray-500">Explorez les services les plus demandés</p>

            <div class="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
                <button
                    v-for="category in serviceCategories"
                    :key="category.id"
                    class="rounded-xl border border-gray-200 bg-white p-5 text-center transition hover:border-brand"
                    @click="() => { serviceCategoryId = category.id; search(); }"
                >
                    <p class="font-medium text-gray-800">{{ category.name }}</p>
                </button>
            </div>
        </section>

        <!-- Comment ça marche -->
        <section class="bg-white px-6 py-16 text-center">
            <h2 class="text-xl font-bold text-gray-900">Comment ça marche ?</h2>
            <div class="mx-auto mt-8 grid max-w-3xl grid-cols-1 gap-8 sm:grid-cols-3">
                <div>
                    <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-brand-light font-bold text-brand">1</div>
                    <p class="mt-3 font-semibold text-gray-900">Recherchez</p>
                    <p class="mt-1 text-sm text-gray-500">Décrivez votre besoin et trouvez les artisans disponibles près de chez vous.</p>
                </div>
                <div>
                    <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-brand-light font-bold text-brand">2</div>
                    <p class="mt-3 font-semibold text-gray-900">Comparez</p>
                    <p class="mt-1 text-sm text-gray-500">Consultez les profils et les devis des prestataires.</p>
                </div>
                <div>
                    <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-brand-light font-bold text-brand">3</div>
                    <p class="mt-3 font-semibold text-gray-900">Choisissez</p>
                    <p class="mt-1 text-sm text-gray-500">Contactez l'artisan idéal et convenez d'un rendez-vous en toute confiance.</p>
                </div>
            </div>
        </section>
    </div>
</template>
VUEEOF

mkdir -p "resources/js/Pages/Search"
cat > "resources/js/Pages/Search/Results.vue" << 'VUEEOF'
<script setup>
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import { ref } from 'vue';

const props = defineProps({
    providers: { type: Array, default: () => [] },
    filters: { type: Object, default: () => ({}) },
    serviceCategories: { type: Array, default: () => [] },
    zones: { type: Array, default: () => [] },
});

const page = usePage();
const isAuthenticated = !!page.props.auth?.user;

const serviceCategoryId = ref(props.filters.service_category_id ?? '');
const zoneId = ref(props.filters.zone_id ?? '');

function search() {
    router.get(route('search.index'), {
        service_category_id: serviceCategoryId.value || undefined,
        zone_id: zoneId.value || undefined,
    });
}

function requestService(providerProfileId) {
    if (!isAuthenticated) {
        router.visit(route('login'));
        return;
    }
    router.visit(route('service-requests.create', { provider_profile_id: providerProfileId }));
}
</script>

<template>
    <Head title="Résultats de recherche" />

    <div class="min-h-screen bg-gray-50">
        <header class="border-b border-gray-200 bg-white">
            <div class="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
                <Link href="/" class="text-lg font-bold text-brand">Service229</Link>
                <Link v-if="isAuthenticated" :href="route('dashboard')" class="text-sm font-medium text-brand hover:underline">
                    Mon tableau de bord
                </Link>
                <Link v-else :href="route('login')" class="text-sm font-medium text-gray-600 hover:text-brand">Connexion</Link>
            </div>
        </header>

        <div class="mx-auto max-w-6xl px-6 py-10">
            <h1 class="text-2xl font-bold text-gray-900">
                {{ providers.length }} prestataire(s) trouvé(s)
            </h1>

            <div class="mt-6 flex flex-col gap-3 rounded-2xl bg-white p-4 shadow-sm sm:flex-row">
                <select v-model="serviceCategoryId" class="flex-1 rounded-lg border-gray-200 text-sm focus:border-brand focus:ring-brand">
                    <option value="">Tous les services</option>
                    <option v-for="category in serviceCategories" :key="category.id" :value="category.id">
                        {{ category.name }}
                    </option>
                </select>
                <select v-model="zoneId" class="flex-1 rounded-lg border-gray-200 text-sm focus:border-brand focus:ring-brand">
                    <option value="">Toutes les zones</option>
                    <option v-for="zone in zones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
                </select>
                <button class="rounded-lg bg-brand px-6 py-2 text-sm font-semibold text-white hover:bg-brand-dark" @click="search">
                    Rechercher
                </button>
            </div>

            <div v-if="providers.length === 0" class="mt-8 rounded-xl border border-dashed border-gray-300 p-12 text-center">
                <p class="text-gray-500">Aucun prestataire ne correspond à cette recherche pour le moment.</p>
            </div>

            <div v-else class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div
                    v-for="provider in providers"
                    :key="provider.id"
                    class="rounded-xl border border-gray-200 bg-white p-5"
                >
                    <div class="flex items-center gap-3">
                        <div class="flex h-12 w-12 items-center justify-center rounded-full bg-brand-light text-lg font-semibold text-brand">
                            {{ provider.user?.name?.charAt(0) }}
                        </div>
                        <div>
                            <p class="font-semibold text-gray-900">{{ provider.user?.name }}</p>
                            <p v-if="provider.services?.length" class="text-sm text-gray-500">
                                {{ provider.services.map((s) => s.name).join(', ') }}
                            </p>
                        </div>
                    </div>
                    <p v-if="provider.zones?.length" class="mt-3 text-sm text-gray-500">
                        📍 {{ provider.zones.map((z) => z.name).join(', ') }}
                    </p>
                    <button
                        class="mt-4 w-full rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
                        @click="requestService(provider.id)"
                    >
                        Demander ce service
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>
VUEEOF

mkdir -p "resources/js/Pages/ServiceRequests"
cat > "resources/js/Pages/ServiceRequests/Create.vue" << 'VUEEOF'
<script setup>
import { useForm } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    serviceCategories: { type: Array, default: () => [] },
    zones: { type: Array, default: () => [] },
    preselectedProviderProfileId: { type: Number, default: null },
});

const form = useForm({
    service_category_id: '',
    zone_id: '',
    provider_profile_id: props.preselectedProviderProfileId,
    title: '',
    description: '',
    budget_estime: '',
    date_intervention: '',
    photos: [],
    as_draft: false,
});

function onPhotosChange(event) {
    form.photos = Array.from(event.target.files);
}

function submit(asDraft) {
    form.as_draft = asDraft;
    form.post(route('service-requests.store'), {
        forceFormData: true,
    });
}
</script>

<template>
    <AppLayout title="Nouvelle demande">
        <div class="mx-auto max-w-3xl">
            <h1 class="text-2xl font-bold text-gray-900">De quel service avez-vous besoin ?</h1>
            <p v-if="form.provider_profile_id" class="mt-2 inline-block rounded-full bg-brand-light px-3 py-1 text-sm text-brand">
                Contact direct — cette demande sera envoyée directement à ce prestataire
            </p>
            <p class="mt-1 text-sm text-gray-500">Décrivez votre besoin, un artisan vous répondra rapidement.</p>

            <form class="mt-8 space-y-6" @submit.prevent>
                <!-- Service -->
                <div>
                    <label for="service_category_id" class="block text-sm font-medium text-gray-700">Service</label>
                    <select
                        id="service_category_id"
                        v-model="form.service_category_id"
                        class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                    >
                        <option value="" disabled>Choisissez un service</option>
                        <option v-for="category in serviceCategories" :key="category.id" :value="category.id">
                            {{ category.name }}
                        </option>
                    </select>
                    <p v-if="form.errors.service_category_id" class="mt-1 text-sm text-red-600">
                        {{ form.errors.service_category_id }}
                    </p>
                </div>

                <!-- Titre -->
                <div>
                    <label for="title" class="block text-sm font-medium text-gray-700">Titre de la demande</label>
                    <input
                        id="title"
                        v-model="form.title"
                        type="text"
                        placeholder="Ex : Pose de carreaux dans mon salon"
                        class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                    />
                    <p v-if="form.errors.title" class="mt-1 text-sm text-red-600">{{ form.errors.title }}</p>
                </div>

                <!-- Description -->
                <div>
                    <label for="description" class="block text-sm font-medium text-gray-700">Description détaillée</label>
                    <textarea
                        id="description"
                        v-model="form.description"
                        rows="4"
                        placeholder="Décrivez votre besoin le plus précisément possible..."
                        class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                    ></textarea>
                    <p v-if="form.errors.description" class="mt-1 text-sm text-red-600">{{ form.errors.description }}</p>
                </div>

                <!-- Lieu + Date -->
                <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                    <div>
                        <label for="zone_id" class="block text-sm font-medium text-gray-700">Lieu</label>
                        <select
                            id="zone_id"
                            v-model="form.zone_id"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        >
                            <option value="" disabled>Choisissez une zone</option>
                            <option v-for="zone in zones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
                        </select>
                        <p v-if="form.errors.zone_id" class="mt-1 text-sm text-red-600">{{ form.errors.zone_id }}</p>
                    </div>

                    <div>
                        <label for="date_intervention" class="block text-sm font-medium text-gray-700">
                            Date d'intervention souhaitée
                        </label>
                        <input
                            id="date_intervention"
                            v-model="form.date_intervention"
                            type="date"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        />
                        <p v-if="form.errors.date_intervention" class="mt-1 text-sm text-red-600">
                            {{ form.errors.date_intervention }}
                        </p>
                    </div>
                </div>

                <!-- Budget -->
                <div>
                    <label for="budget_estime" class="block text-sm font-medium text-gray-700">
                        Budget estimé <span class="font-normal text-gray-400">(Optionnel)</span>
                    </label>
                    <div class="relative mt-1">
                        <input
                            id="budget_estime"
                            v-model="form.budget_estime"
                            type="number"
                            min="0"
                            placeholder="60000"
                            class="block w-full rounded-lg border-gray-300 pr-16 focus:border-brand focus:ring-brand"
                        />
                        <span class="absolute inset-y-0 right-3 flex items-center text-sm text-gray-400">FCFA</span>
                    </div>
                    <p v-if="form.errors.budget_estime" class="mt-1 text-sm text-red-600">{{ form.errors.budget_estime }}</p>
                </div>

                <!-- Photos -->
                <div>
                    <label class="block text-sm font-medium text-gray-700">Photos <span class="font-normal text-gray-400">(Optionnel)</span></label>
                    <label
                        for="photos"
                        class="mt-1 flex cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed border-gray-300 px-6 py-10 text-center hover:border-brand"
                    >
                        <span class="font-semibold text-brand">Ajouter des photos de votre besoin</span>
                        <span class="mt-1 text-xs text-gray-400">JPG, PNG jusqu'à 5MB — 5 photos maximum</span>
                        <input id="photos" type="file" accept="image/png,image/jpeg" multiple class="hidden" @change="onPhotosChange" />
                    </label>
                    <p v-if="form.photos.length" class="mt-2 text-sm text-gray-500">
                        {{ form.photos.length }} photo(s) sélectionnée(s)
                    </p>
                    <p v-if="form.errors['photos']" class="mt-1 text-sm text-red-600">{{ form.errors['photos'] }}</p>
                </div>

                <!-- Actions -->
                <div class="flex flex-col gap-3 border-t border-gray-100 pt-6 sm:flex-row">
                    <button
                        type="button"
                        :disabled="form.processing"
                        class="flex-1 rounded-lg bg-accent px-6 py-3 text-center font-semibold text-white transition hover:bg-accent-dark disabled:opacity-50"
                        @click="submit(false)"
                    >
                        Publier ma demande
                    </button>
                    <button
                        type="button"
                        :disabled="form.processing"
                        class="flex-1 rounded-lg border border-brand px-6 py-3 text-center font-semibold text-brand transition hover:bg-brand-light disabled:opacity-50"
                        @click="submit(true)"
                    >
                        Enregistrer en brouillon
                    </button>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages/ServiceRequests"
cat > "resources/js/Pages/ServiceRequests/Index.vue" << 'VUEEOF'
<script setup>
import { Link, router } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

defineProps({
    serviceRequests: { type: Object, required: true },
});

const statusLabels = {
    draft: { text: 'Brouillon', class: 'bg-gray-100 text-gray-600' },
    published: { text: 'En attente de devis', class: 'bg-amber-100 text-amber-700' },
    matched: { text: 'Propositions reçues', class: 'bg-blue-100 text-blue-700' },
    assigned: { text: 'Artisan assigné', class: 'bg-brand-light text-brand' },
    cancelled: { text: 'Annulée', class: 'bg-gray-100 text-gray-500' },
    expired: { text: 'Expirée', class: 'bg-gray-100 text-gray-500' },
    closed: { text: 'Terminée', class: 'bg-green-100 text-green-700' },
};

function destroyDraft(id) {
    if (!confirm('Supprimer définitivement ce brouillon ?')) return;
    router.delete(route('service-requests.destroy', id));
}
</script>

<template>
    <AppLayout title="Mes demandes">
        <div class="mb-6 flex items-center justify-between">
            <h1 class="text-2xl font-bold text-gray-900">Mes demandes</h1>
            <Link
                :href="route('service-requests.create')"
                class="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
            >
                + Nouvelle demande
            </Link>
        </div>

        <div v-if="serviceRequests.data.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Vous n'avez encore publié aucune demande.</p>
            <Link :href="route('service-requests.create')" class="mt-3 inline-block font-semibold text-brand hover:underline">
                Publier votre première demande
            </Link>
        </div>

        <div v-else class="space-y-3">
            <div
                v-for="sr in serviceRequests.data"
                :key="sr.id"
                class="rounded-xl border border-gray-200 bg-white p-5 transition hover:border-brand hover:shadow-sm"
            >
                <Link :href="sr.status === 'draft' ? undefined : route('service-requests.show', sr.id)" class="block">
                    <div class="flex items-start justify-between gap-4">
                        <div class="min-w-0">
                            <h2 class="truncate font-semibold text-gray-900">{{ sr.title }}</h2>
                            <p class="mt-1 text-sm text-gray-500">
                                {{ sr.service_category?.name }} · {{ sr.zone?.name }}
                            </p>
                            <p v-if="sr.proposals?.length" class="mt-2 text-sm text-brand">
                                {{ sr.proposals.length }} devis reçu(s)
                            </p>
                        </div>
                        <span
                            class="shrink-0 rounded-full px-3 py-1 text-xs font-medium"
                            :class="statusLabels[sr.status]?.class"
                        >
                            {{ statusLabels[sr.status]?.text ?? sr.status }}
                        </span>
                    </div>
                </Link>

                <!-- Actions spécifiques aux brouillons -->
                <div v-if="sr.status === 'draft'" class="mt-4 flex gap-3 border-t border-gray-100 pt-4">
                    <Link
                        :href="route('service-requests.edit', sr.id)"
                        class="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
                    >
                        Continuer la demande
                    </Link>
                    <button
                        class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50"
                        @click="destroyDraft(sr.id)"
                    >
                        Supprimer
                    </button>
                </div>
            </div>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages/ServiceRequests"
cat > "resources/js/Pages/ServiceRequests/Show.vue" << 'VUEEOF'
<script setup>
import { router, useForm, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    serviceRequest: { type: Object, required: true },
});

const page = usePage();
const currentUserId = computed(() => page.props.auth?.user?.id);
const isClient = computed(() => props.serviceRequest.client_id === currentUserId.value);
const isProvider = computed(() => page.props.auth?.user?.estPrestataire && !isClient.value);

const myProposal = computed(() =>
    props.serviceRequest.proposals?.find((p) => p.provider_profile?.user?.id === currentUserId.value)
);

const canCancel = computed(() =>
    isClient.value && !['closed', 'cancelled'].includes(props.serviceRequest.status)
);

// Prestataire à contacter côté client : celui de la demande (Mode 1) ou celui
// dont le devis est accepté (Mode 2)
const contactableProviderProfileId = computed(() => {
    if (props.serviceRequest.provider_profile_id) return props.serviceRequest.provider_profile_id;
    const accepted = props.serviceRequest.proposals?.find((p) => p.status === 'accepted');
    return accepted?.provider_profile_id ?? null;
});

function contactProvider() {
    router.post(route('conversations.start-or-find'), {
        provider_profile_id: contactableProviderProfileId.value,
    });
}

function contactClient() {
    router.post(route('conversations.start-or-find'), {
        client_id: props.serviceRequest.client_id,
    });
}

function acceptProposal(proposalId) {
    if (!confirm('Accepter ce devis ? Les autres devis en attente seront automatiquement refusés.')) return;
    router.patch(route('proposals.accept', proposalId));
}

function rejectProposal(proposalId) {
    router.patch(route('proposals.reject', proposalId));
}

function cancelRequest() {
    if (!confirm('Annuler cette demande ?')) return;
    router.patch(route('service-requests.cancel', props.serviceRequest.id));
}

const proposalForm = useForm({
    montant: '',
    delai: '',
    description: '',
});

function submitProposal() {
    proposalForm.post(route('proposals.store', props.serviceRequest.id));
}
</script>

<template>
    <AppLayout :title="serviceRequest.title">
        <div class="mx-auto max-w-3xl">
            <div class="flex items-start justify-between">
                <div>
                    <h1 class="text-2xl font-bold text-gray-900">{{ serviceRequest.title }}</h1>
                    <p class="mt-1 text-sm text-gray-500">
                        {{ serviceRequest.service_category?.name }} · {{ serviceRequest.zone?.name }}
                        <span v-if="serviceRequest.budget_estime"> · Budget : {{ serviceRequest.budget_estime }} FCFA</span>
                    </p>
                </div>
                <button
                    v-if="canCancel"
                    class="shrink-0 text-sm font-medium text-red-600 hover:underline"
                    @click="cancelRequest"
                >
                    Annuler la demande
                </button>
            </div>

            <div v-if="serviceRequest.description" class="mt-4 rounded-xl bg-white p-5 text-gray-700">
                {{ serviceRequest.description }}
            </div>

            <!-- Contact -->
            <div class="mt-4 flex gap-3">
                <button
                    v-if="isClient && contactableProviderProfileId"
                    class="rounded-lg border border-brand px-4 py-2 text-sm font-semibold text-brand hover:bg-brand-light"
                    @click="contactProvider"
                >
                    💬 Envoyer un message au prestataire
                </button>
                <button
                    v-if="isProvider"
                    class="rounded-lg border border-brand px-4 py-2 text-sm font-semibold text-brand hover:bg-brand-light"
                    @click="contactClient"
                >
                    💬 Envoyer un message au client
                </button>
            </div>

            <div v-if="serviceRequest.photos?.length" class="mt-4 grid grid-cols-3 gap-3">
                <img
                    v-for="photo in serviceRequest.photos"
                    :key="photo.id"
                    :src="photo.url"
                    class="h-24 w-full rounded-lg object-cover"
                    alt="Photo de la demande"
                />
            </div>

            <!-- Formulaire de devis (prestataire uniquement, s'il n'a pas déjà répondu) -->
            <div
                v-if="isProvider && serviceRequest.status === 'published' && !myProposal"
                class="mt-8 rounded-xl border border-gray-200 bg-white p-5"
            >
                <h2 class="text-lg font-semibold text-gray-900">Envoyer un devis</h2>
                <form class="mt-4 space-y-4" @submit.prevent="submitProposal">
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Montant (FCFA)</label>
                            <input
                                v-model="proposalForm.montant"
                                type="number"
                                min="0"
                                class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                            />
                            <p v-if="proposalForm.errors.montant" class="mt-1 text-sm text-red-600">{{ proposalForm.errors.montant }}</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Délai</label>
                            <input
                                v-model="proposalForm.delai"
                                type="text"
                                placeholder="Ex : 3 jours"
                                class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                            />
                            <p v-if="proposalForm.errors.delai" class="mt-1 text-sm text-red-600">{{ proposalForm.errors.delai }}</p>
                        </div>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Description de votre proposition</label>
                        <textarea
                            v-model="proposalForm.description"
                            rows="3"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        ></textarea>
                        <p v-if="proposalForm.errors.description" class="mt-1 text-sm text-red-600">{{ proposalForm.errors.description }}</p>
                    </div>
                    <button
                        type="submit"
                        :disabled="proposalForm.processing"
                        class="rounded-lg bg-accent px-5 py-2 text-sm font-semibold text-white hover:bg-accent-dark disabled:opacity-50"
                    >
                        Envoyer le devis
                    </button>
                </form>
            </div>

            <p v-else-if="isProvider && myProposal" class="mt-8 text-sm text-gray-500">
                Vous avez déjà envoyé un devis pour cette demande ({{ myProposal.montant }} FCFA — statut : {{ myProposal.status }}).
            </p>

            <!-- Devis reçus (client uniquement) -->
            <div v-if="isClient" class="mt-8">
                <h2 class="text-lg font-semibold text-gray-900">
                    Devis reçus <span class="text-gray-400">({{ serviceRequest.proposals?.length ?? 0 }})</span>
                </h2>

                <p v-if="!serviceRequest.proposals?.length" class="mt-3 text-sm text-gray-500">
                    Aucun devis reçu pour le moment.
                </p>

                <div v-else class="mt-4 space-y-4">
                    <div
                        v-for="proposal in serviceRequest.proposals"
                        :key="proposal.id"
                        class="rounded-xl border border-gray-200 bg-white p-5"
                    >
                        <div class="flex items-start justify-between">
                            <div>
                                <p class="font-semibold text-gray-900">
                                    {{ proposal.provider_profile?.user?.name ?? 'Prestataire' }}
                                </p>
                                <p class="mt-1 text-sm text-gray-500">Délai : {{ proposal.delai }}</p>
                                <p class="mt-2 text-sm text-gray-700">{{ proposal.description }}</p>
                            </div>
                            <p class="shrink-0 text-lg font-bold text-brand">{{ proposal.montant }} FCFA</p>
                        </div>

                        <div v-if="proposal.status === 'pending'" class="mt-4 flex gap-3">
                            <button
                                class="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
                                @click="acceptProposal(proposal.id)"
                            >
                                Accepter ce devis
                            </button>
                            <button
                                class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50"
                                @click="rejectProposal(proposal.id)"
                            >
                                Refuser
                            </button>
                        </div>
                        <span
                            v-else
                            class="mt-4 inline-block rounded-full px-3 py-1 text-xs font-medium"
                            :class="{
                                'bg-brand-light text-brand': proposal.status === 'accepted',
                                'bg-gray-100 text-gray-500': proposal.status !== 'accepted',
                            }"
                        >
                            {{ proposal.status === 'accepted' ? 'Accepté' : 'Refusé' }}
                        </span>
                    </div>
                </div>
            </div>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages/ServiceRequests"
cat > "resources/js/Pages/ServiceRequests/Edit.vue" << 'VUEEOF'
<script setup>
import { useForm, router } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    serviceRequest: { type: Object, required: true },
    serviceCategories: { type: Array, default: () => [] },
    zones: { type: Array, default: () => [] },
});

const form = useForm({
    service_category_id: props.serviceRequest.service_category_id ?? '',
    zone_id: props.serviceRequest.zone_id ?? '',
    title: props.serviceRequest.title ?? '',
    description: props.serviceRequest.description ?? '',
    budget_estime: props.serviceRequest.budget_estime ?? '',
    date_intervention: props.serviceRequest.date_intervention ?? '',
    photos: [],
    as_draft: false,
});

function onPhotosChange(event) {
    form.photos = Array.from(event.target.files);
}

function submit(asDraft) {
    form.as_draft = asDraft;
    form.transform((data) => ({ ...data, _method: 'put' })).post(
        route('service-requests.update', props.serviceRequest.id),
        { forceFormData: true }
    );
}

function destroyDraft() {
    if (!confirm('Supprimer définitivement ce brouillon ? Cette action est irréversible.')) return;
    router.delete(route('service-requests.destroy', props.serviceRequest.id));
}
</script>

<template>
    <AppLayout title="Continuer le brouillon">
        <div class="mx-auto max-w-3xl">
            <div class="flex items-center justify-between">
                <h1 class="text-2xl font-bold text-gray-900">Continuer votre brouillon</h1>
                <button class="text-sm font-medium text-red-600 hover:underline" @click="destroyDraft">
                    Supprimer ce brouillon
                </button>
            </div>

            <form class="mt-8 space-y-6" @submit.prevent>
                <div>
                    <label for="service_category_id" class="block text-sm font-medium text-gray-700">Service</label>
                    <select
                        id="service_category_id"
                        v-model="form.service_category_id"
                        class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                    >
                        <option value="" disabled>Choisissez un service</option>
                        <option v-for="category in serviceCategories" :key="category.id" :value="category.id">
                            {{ category.name }}
                        </option>
                    </select>
                    <p v-if="form.errors.service_category_id" class="mt-1 text-sm text-red-600">
                        {{ form.errors.service_category_id }}
                    </p>
                </div>

                <div>
                    <label for="title" class="block text-sm font-medium text-gray-700">Titre de la demande</label>
                    <input
                        id="title"
                        v-model="form.title"
                        type="text"
                        class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                    />
                    <p v-if="form.errors.title" class="mt-1 text-sm text-red-600">{{ form.errors.title }}</p>
                </div>

                <div>
                    <label for="description" class="block text-sm font-medium text-gray-700">Description détaillée</label>
                    <textarea
                        id="description"
                        v-model="form.description"
                        rows="4"
                        class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                    ></textarea>
                    <p v-if="form.errors.description" class="mt-1 text-sm text-red-600">{{ form.errors.description }}</p>
                </div>

                <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                    <div>
                        <label for="zone_id" class="block text-sm font-medium text-gray-700">Lieu</label>
                        <select
                            id="zone_id"
                            v-model="form.zone_id"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        >
                            <option value="" disabled>Choisissez une zone</option>
                            <option v-for="zone in zones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
                        </select>
                        <p v-if="form.errors.zone_id" class="mt-1 text-sm text-red-600">{{ form.errors.zone_id }}</p>
                    </div>

                    <div>
                        <label for="date_intervention" class="block text-sm font-medium text-gray-700">
                            Date d'intervention souhaitée
                        </label>
                        <input
                            id="date_intervention"
                            v-model="form.date_intervention"
                            type="date"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        />
                        <p v-if="form.errors.date_intervention" class="mt-1 text-sm text-red-600">
                            {{ form.errors.date_intervention }}
                        </p>
                    </div>
                </div>

                <div>
                    <label for="budget_estime" class="block text-sm font-medium text-gray-700">
                        Budget estimé <span class="font-normal text-gray-400">(Optionnel)</span>
                    </label>
                    <div class="relative mt-1">
                        <input
                            id="budget_estime"
                            v-model="form.budget_estime"
                            type="number"
                            min="0"
                            class="block w-full rounded-lg border-gray-300 pr-16 focus:border-brand focus:ring-brand"
                        />
                        <span class="absolute inset-y-0 right-3 flex items-center text-sm text-gray-400">FCFA</span>
                    </div>
                    <p v-if="form.errors.budget_estime" class="mt-1 text-sm text-red-600">{{ form.errors.budget_estime }}</p>
                </div>

                <div v-if="serviceRequest.photos?.length" class="grid grid-cols-4 gap-3">
                    <img
                        v-for="photo in serviceRequest.photos"
                        :key="photo.id"
                        :src="photo.url"
                        class="h-20 w-full rounded-lg object-cover"
                        alt="Photo déjà ajoutée"
                    />
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700">
                        Ajouter d'autres photos <span class="font-normal text-gray-400">(Optionnel)</span>
                    </label>
                    <label
                        for="photos"
                        class="mt-1 flex cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed border-gray-300 px-6 py-10 text-center hover:border-brand"
                    >
                        <span class="font-semibold text-brand">Ajouter des photos de votre besoin</span>
                        <span class="mt-1 text-xs text-gray-400">JPG, PNG jusqu'à 5MB — 5 photos maximum</span>
                        <input id="photos" type="file" accept="image/png,image/jpeg" multiple class="hidden" @change="onPhotosChange" />
                    </label>
                    <p v-if="form.photos.length" class="mt-2 text-sm text-gray-500">
                        {{ form.photos.length }} nouvelle(s) photo(s) sélectionnée(s)
                    </p>
                </div>

                <div class="flex flex-col gap-3 border-t border-gray-100 pt-6 sm:flex-row">
                    <button
                        type="button"
                        :disabled="form.processing"
                        class="flex-1 rounded-lg bg-accent px-6 py-3 text-center font-semibold text-white transition hover:bg-accent-dark disabled:opacity-50"
                        @click="submit(false)"
                    >
                        Publier ma demande
                    </button>
                    <button
                        type="button"
                        :disabled="form.processing"
                        class="flex-1 rounded-lg border border-brand px-6 py-3 text-center font-semibold text-brand transition hover:bg-brand-light disabled:opacity-50"
                        @click="submit(true)"
                    >
                        Continuer plus tard (garder en brouillon)
                    </button>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages/ServiceRequests"
cat > "resources/js/Pages/ServiceRequests/Browse.vue" << 'VUEEOF'
<script setup>
import { Link } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

defineProps({
    serviceRequests: { type: Object, required: true },
});
</script>

<template>
    <AppLayout title="Demandes disponibles">
        <h1 class="mb-1 text-2xl font-bold text-gray-900">Demandes disponibles</h1>
        <p class="mb-6 text-sm text-gray-500">Demandes correspondant à vos services et zones déclarés.</p>

        <div v-if="serviceRequests.data.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Aucune demande disponible pour le moment.</p>
        </div>

        <div v-else class="space-y-3">
            <Link
                v-for="sr in serviceRequests.data"
                :key="sr.id"
                :href="route('service-requests.show', sr.id)"
                class="block rounded-xl border border-gray-200 bg-white p-5 transition hover:border-brand hover:shadow-sm"
            >
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <h2 class="font-semibold text-gray-900">{{ sr.title }}</h2>
                        <p class="mt-1 text-sm text-gray-500">
                            {{ sr.service_category?.name }} · {{ sr.zone?.name }}
                        </p>
                        <p v-if="sr.budget_estime" class="mt-2 text-sm font-semibold text-brand">
                            Budget : {{ sr.budget_estime }} FCFA
                        </p>
                        <p v-else class="mt-2 text-sm text-gray-400">Budget à discuter</p>
                    </div>
                    <span class="shrink-0 rounded-full bg-brand-light px-3 py-1 text-xs font-medium text-brand">
                        Nouveau
                    </span>
                </div>
            </Link>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages/Missions"
cat > "resources/js/Pages/Missions/Index.vue" << 'VUEEOF'
<script setup>
import { Link } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

defineProps({
    missions: { type: Object, required: true },
});

const statusLabels = {
    pending: { text: 'En attente', class: 'bg-gray-100 text-gray-600' },
    in_progress: { text: 'En cours', class: 'bg-blue-100 text-blue-700' },
    awaiting_confirmation: { text: 'À confirmer', class: 'bg-amber-100 text-amber-700' },
    completed: { text: 'Terminée', class: 'bg-green-100 text-green-700' },
    cancelled: { text: 'Annulée', class: 'bg-gray-100 text-gray-500' },
    disputed: { text: 'Litige', class: 'bg-red-100 text-red-700' },
};
</script>

<template>
    <AppLayout title="Mes missions">
        <h1 class="mb-6 text-2xl font-bold text-gray-900">Mes missions</h1>

        <div v-if="missions.data.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Aucune mission pour le moment.</p>
        </div>

        <div v-else class="space-y-3">
            <Link
                v-for="mission in missions.data"
                :key="mission.id"
                :href="route('missions.show', mission.id)"
                class="flex items-center justify-between rounded-xl border border-gray-200 bg-white p-5 transition hover:border-brand hover:shadow-sm"
            >
                <div>
                    <h2 class="font-semibold text-gray-900">{{ mission.service_request?.title }}</h2>
                    <p class="mt-1 text-sm text-gray-500">
                        {{ mission.provider_profile?.user?.name ?? mission.client?.name }}
                    </p>
                </div>
                <span
                    class="shrink-0 rounded-full px-3 py-1 text-xs font-medium"
                    :class="statusLabels[mission.status]?.class"
                >
                    {{ statusLabels[mission.status]?.text ?? mission.status }}
                </span>
            </Link>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages/Missions"
cat > "resources/js/Pages/Missions/Show.vue" << 'VUEEOF'
<script setup>
import { router, useForm, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    mission: { type: Object, required: true },
});

const page = usePage();
const currentUserId = computed(() => page.props.auth?.user?.id);
const isProvider = computed(() => props.mission.provider_profile?.user?.id === currentUserId.value);
const isClient = computed(() => props.mission.client?.id === currentUserId.value);

const steps = ['pending', 'in_progress', 'awaiting_confirmation', 'completed'];
const currentStepIndex = computed(() => steps.indexOf(props.mission.status));

function startMission() {
    router.patch(route('missions.start', props.mission.id));
}
function markAwaitingConfirmation() {
    router.patch(route('missions.mark-awaiting-confirmation', props.mission.id));
}
function confirmCompletion() {
    router.patch(route('missions.confirm-completion', props.mission.id));
}
function markPaid() {
    router.patch(route('missions.mark-paid', props.mission.id));
}

function contactOtherParty() {
    if (isClient.value) {
        router.post(route('conversations.start-or-find'), {
            provider_profile_id: props.mission.provider_profile_id,
        });
    } else {
        router.post(route('conversations.start-or-find'), {
            client_id: props.mission.client_id,
        });
    }
}

const reviewForm = useForm({ note: 5, commentaire: '' });

function submitReview() {
    reviewForm.post(route('reviews.store', props.mission.id));
}
</script>

<template>
    <AppLayout :title="mission.service_request?.title">
        <div class="mx-auto max-w-2xl">
            <h1 class="text-2xl font-bold text-gray-900">{{ mission.service_request?.title }}</h1>
            <p class="mt-1 text-sm text-gray-500">
                {{ isClient ? mission.provider_profile?.user?.name : mission.client?.name }}
            </p>
            <button
                class="mt-2 text-sm font-medium text-brand hover:underline"
                @click="contactOtherParty"
            >
                💬 Envoyer un message
            </button>

            <!-- Stepper de statut -->
            <div v-if="mission.status !== 'cancelled' && mission.status !== 'disputed'" class="mt-8 flex items-center">
                <template v-for="(step, index) in steps" :key="step">
                    <div class="flex flex-col items-center">
                        <div
                            class="flex h-8 w-8 items-center justify-center rounded-full text-xs font-semibold"
                            :class="index <= currentStepIndex ? 'bg-brand text-white' : 'bg-gray-200 text-gray-500'"
                        >
                            {{ index + 1 }}
                        </div>
                    </div>
                    <div
                        v-if="index < steps.length - 1"
                        class="mx-1 h-0.5 flex-1"
                        :class="index < currentStepIndex ? 'bg-brand' : 'bg-gray-200'"
                    ></div>
                </template>
            </div>
            <span
                v-else
                class="mt-6 inline-block rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-700"
            >
                {{ mission.status === 'cancelled' ? 'Mission annulée' : 'En litige' }}
            </span>

            <!-- Actions selon rôle et statut -->
            <div class="mt-8 space-y-3">
                <button
                    v-if="isProvider && mission.status === 'pending'"
                    class="w-full rounded-lg bg-accent px-4 py-3 font-semibold text-white hover:bg-accent-dark"
                    @click="startMission"
                >
                    Démarrer la mission
                </button>

                <button
                    v-if="isProvider && mission.status === 'in_progress'"
                    class="w-full rounded-lg bg-accent px-4 py-3 font-semibold text-white hover:bg-accent-dark"
                    @click="markAwaitingConfirmation"
                >
                    Signaler le travail comme terminé
                </button>

                <button
                    v-if="isClient && mission.status === 'awaiting_confirmation'"
                    class="w-full rounded-lg bg-accent px-4 py-3 font-semibold text-white hover:bg-accent-dark"
                    @click="confirmCompletion"
                >
                    Confirmer que le travail est terminé
                </button>

                <button
                    v-if="isClient && !mission.paiementEffectue && mission.status === 'completed'"
                    class="w-full rounded-lg border border-brand px-4 py-3 font-semibold text-brand hover:bg-brand-light"
                    @click="markPaid"
                >
                    Marquer comme payé
                </button>

                <p v-if="mission.paiementEffectue" class="text-center text-sm font-medium text-green-700">
                    ✓ Paiement effectué
                </p>
            </div>

            <!-- Avis -->
            <div v-if="mission.status === 'completed' && isClient && !mission.review" class="mt-8 rounded-xl border border-gray-200 bg-white p-5">
                <h2 class="font-semibold text-gray-900">Laisser un avis</h2>
                <form class="mt-4 space-y-4" @submit.prevent="submitReview">
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Note</label>
                        <div class="mt-1 flex gap-1">
                            <button
                                v-for="n in 5"
                                :key="n"
                                type="button"
                                class="text-2xl"
                                :class="n <= reviewForm.note ? 'text-accent' : 'text-gray-300'"
                                @click="reviewForm.note = n"
                            >
                                ★
                            </button>
                        </div>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Commentaire (optionnel)</label>
                        <textarea
                            v-model="reviewForm.commentaire"
                            rows="3"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        ></textarea>
                    </div>
                    <button
                        type="submit"
                        :disabled="reviewForm.processing"
                        class="rounded-lg bg-accent px-5 py-2 text-sm font-semibold text-white hover:bg-accent-dark disabled:opacity-50"
                    >
                        Publier l'avis
                    </button>
                </form>
            </div>

            <div v-else-if="mission.review" class="mt-8 rounded-xl border border-gray-200 bg-white p-5">
                <p class="text-sm font-medium text-gray-900">Votre avis : {{ mission.review.note }}/5</p>
                <p v-if="mission.review.commentaire" class="mt-1 text-sm text-gray-600">{{ mission.review.commentaire }}</p>
            </div>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages/Notifications"
cat > "resources/js/Pages/Notifications/Index.vue" << 'VUEEOF'
<script setup>
import { Link, router } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

defineProps({
    notifications: { type: Object, required: true },
});

function markAllAsRead() {
    router.patch(route('notifications.mark-all-as-read'));
}

function openNotification(notification) {
    if (!notification.lu) {
        router.patch(route('notifications.mark-as-read', notification.id));
    }
    if (notification.lien_associe) {
        router.visit(notification.lien_associe);
    }
}
</script>

<template>
    <AppLayout title="Notifications">
        <div class="mb-6 flex items-center justify-between">
            <h1 class="text-2xl font-bold text-gray-900">Notifications</h1>
            <button class="text-sm font-medium text-brand hover:underline" @click="markAllAsRead">
                Tout marquer comme lu
            </button>
        </div>

        <div v-if="notifications.data.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Aucune notification pour le moment.</p>
        </div>

        <div v-else class="space-y-2">
            <button
                v-for="notification in notifications.data"
                :key="notification.id"
                class="flex w-full items-start gap-3 rounded-xl border p-4 text-left transition hover:border-brand"
                :class="notification.lu ? 'border-gray-200 bg-white' : 'border-brand-light bg-brand-light/40'"
                @click="openNotification(notification)"
            >
                <span
                    v-if="!notification.lu"
                    class="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-accent"
                ></span>
                <span v-else class="mt-1.5 h-2 w-2 shrink-0"></span>
                <span class="text-sm text-gray-700">{{ notification.message }}</span>
            </button>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages/Conversations"
cat > "resources/js/Pages/Conversations/Index.vue" << 'VUEEOF'
<script setup>
import { Link, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    conversations: { type: Array, required: true },
});

const page = usePage();
const currentUserId = computed(() => page.props.auth?.user?.id);

function otherPartyName(conversation) {
    const isClient = conversation.client_id === currentUserId.value;
    return isClient
        ? conversation.provider_profile?.user?.name
        : conversation.client?.name;
}
</script>

<template>
    <AppLayout title="Messagerie">
        <h1 class="mb-6 text-2xl font-bold text-gray-900">Messagerie</h1>

        <div v-if="conversations.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Aucune conversation pour le moment.</p>
        </div>

        <div v-else class="space-y-2">
            <Link
                v-for="conversation in conversations"
                :key="conversation.id"
                :href="route('conversations.show', conversation.id)"
                class="flex items-center justify-between rounded-xl border border-gray-200 bg-white p-4 transition hover:border-brand hover:shadow-sm"
            >
                <div class="flex items-center gap-3">
                    <div class="flex h-10 w-10 items-center justify-center rounded-full bg-brand-light text-sm font-semibold text-brand">
                        {{ otherPartyName(conversation)?.charAt(0) }}
                    </div>
                    <div>
                        <p class="font-semibold text-gray-900">{{ otherPartyName(conversation) }}</p>
                        <p v-if="conversation.service_request" class="text-sm text-gray-500">
                            {{ conversation.service_request.title }}
                        </p>
                    </div>
                </div>
                <span
                    v-if="conversation.unread_count > 0"
                    class="rounded-full bg-accent px-2 py-0.5 text-xs font-semibold text-white"
                >
                    {{ conversation.unread_count }}
                </span>
            </Link>
        </div>
    </AppLayout>
</template>
VUEEOF

mkdir -p "resources/js/Pages/Conversations"
cat > "resources/js/Pages/Conversations/Show.vue" << 'VUEEOF'
<script setup>
import { useForm, usePage } from '@inertiajs/vue3';
import { computed, nextTick, onMounted, ref } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    conversation: { type: Object, required: true },
});

const page = usePage();
const currentUserId = computed(() => page.props.auth?.user?.id);

const isClient = computed(() => props.conversation.client_id === currentUserId.value);
const otherPartyName = computed(() =>
    isClient.value ? props.conversation.provider_profile?.user?.name : props.conversation.client?.name
);

const form = useForm({ content: '' });
const messagesEnd = ref(null);

function send() {
    if (!form.content.trim()) return;
    form.post(route('messages.store', props.conversation.id), {
        preserveScroll: true,
        onSuccess: () => {
            form.reset();
            nextTick(() => messagesEnd.value?.scrollIntoView());
        },
    });
}

onMounted(() => messagesEnd.value?.scrollIntoView());
</script>

<template>
    <AppLayout :title="otherPartyName">
        <div class="mx-auto flex h-[calc(100vh-8rem)] max-w-2xl flex-col">
            <h1 class="border-b border-gray-200 pb-4 text-lg font-semibold text-gray-900">
                {{ otherPartyName }}
                <span v-if="conversation.service_request" class="block text-sm font-normal text-gray-500">
                    {{ conversation.service_request.title }}
                </span>
            </h1>

            <div class="flex-1 space-y-3 overflow-y-auto py-4">
                <div
                    v-for="message in conversation.messages"
                    :key="message.id"
                    class="flex"
                    :class="message.sender_id === currentUserId ? 'justify-end' : 'justify-start'"
                >
                    <div
                        class="max-w-xs rounded-2xl px-4 py-2 text-sm"
                        :class="message.sender_id === currentUserId
                            ? 'bg-brand text-white'
                            : 'bg-gray-100 text-gray-800'"
                    >
                        {{ message.content }}
                    </div>
                </div>
                <div ref="messagesEnd"></div>
            </div>

            <form class="flex gap-2 border-t border-gray-200 pt-4" @submit.prevent="send">
                <input
                    v-model="form.content"
                    type="text"
                    placeholder="Écrire un message..."
                    class="flex-1 rounded-full border-gray-300 focus:border-brand focus:ring-brand"
                />
                <button
                    type="submit"
                    :disabled="form.processing || !form.content.trim()"
                    class="rounded-full bg-accent px-5 py-2 text-sm font-semibold text-white hover:bg-accent-dark disabled:opacity-50"
                >
                    Envoyer
                </button>
            </form>
        </div>
    </AppLayout>
</template>
VUEEOF

cat > "tailwind.config.js" << 'JSEOF'
import defaultTheme from 'tailwindcss/defaultTheme';
import forms from '@tailwindcss/forms';

/** @type {import('tailwindcss').Config} */
export default {
    content: [
        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/views/**/*.blade.php',
        './resources/js/**/*.vue',
    ],

    theme: {
        extend: {
            fontFamily: {
                sans: ['Figtree', ...defaultTheme.fontFamily.sans],
            },
            colors: {
                // Couleurs validées dans la maquette Stitch (7 écrans, groupe D)
                brand: {
                    DEFAULT: '#166534', // vert principal (logo, CTA secondaires, liens actifs)
                    dark: '#14532d',
                    light: '#dcfce7',
                },
                accent: {
                    DEFAULT: '#F97316', // orange — CTA principaux ("Demander ce service", "Publier ma demande")
                    dark: '#c2410c',
                    light: '#ffedd5',
                },
            },
        },
    },

    plugins: [forms],
};
JSEOF

mkdir -p "resources/js"
cat > "resources/js/bootstrap.js" << 'JSEOF'
import axios from 'axios';
window.axios = axios;

window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
JSEOF

echo "== Fichier de référence routes Inertia (À FUSIONNER MANUELLEMENT dans routes/web.php) =="

cat > "routes_pole_abed.php" << 'REFEOF1'
<?php
// EMPLACEMENT : routes/web.php
// (à FUSIONNER — remplace la route "/" et "dashboard" de Breeze par
// celles-ci, ajoute le reste à la suite)

use App\Http\Controllers\ConversationController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\MessageController;
use App\Http\Controllers\MissionController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\ProposalController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\ServiceRequestController;
use Illuminate\Support\Facades\Route;

// Pages publiques (pas besoin d'être connecté)
Route::get('/', [SearchController::class, 'home'])->name('home');
Route::get('/recherche', [SearchController::class, 'index'])->name('search.index');

// ⚠️ Remplace la route "dashboard" générée par Breeze par celle-ci :
Route::get('/dashboard', [DashboardController::class, 'index'])
    ->middleware(['auth', 'verified'])
    ->name('dashboard');

Route::middleware('auth')->group(function () {
    // ServiceRequests
    Route::get('/service-requests', [ServiceRequestController::class, 'index'])->name('service-requests.index');
    Route::get('/service-requests/create', [ServiceRequestController::class, 'create'])->name('service-requests.create');
    Route::post('/service-requests', [ServiceRequestController::class, 'store'])->name('service-requests.store');
    Route::get('/service-requests/browse', [ServiceRequestController::class, 'browse'])->name('service-requests.browse');
    Route::get('/service-requests/{serviceRequest}', [ServiceRequestController::class, 'show'])->name('service-requests.show');
    Route::get('/service-requests/{serviceRequest}/edit', [ServiceRequestController::class, 'edit'])->name('service-requests.edit');
    Route::put('/service-requests/{serviceRequest}', [ServiceRequestController::class, 'update'])->name('service-requests.update');
    Route::delete('/service-requests/{serviceRequest}', [ServiceRequestController::class, 'destroy'])->name('service-requests.destroy');
    Route::patch('/service-requests/{serviceRequest}/cancel', [ServiceRequestController::class, 'cancel'])->name('service-requests.cancel');

    // Proposals
    Route::post('/service-requests/{serviceRequest}/proposals', [ProposalController::class, 'store'])->name('proposals.store');
    Route::patch('/proposals/{proposal}/accept', [ProposalController::class, 'accept'])->name('proposals.accept');
    Route::patch('/proposals/{proposal}/reject', [ProposalController::class, 'reject'])->name('proposals.reject');
    Route::patch('/proposals/{proposal}/withdraw', [ProposalController::class, 'withdraw'])->name('proposals.withdraw');

    // Missions
    Route::get('/missions', [MissionController::class, 'index'])->name('missions.index');
    Route::get('/missions/{mission}', [MissionController::class, 'show'])->name('missions.show');
    Route::patch('/missions/{mission}/start', [MissionController::class, 'start'])->name('missions.start');
    Route::patch('/missions/{mission}/mark-awaiting-confirmation', [MissionController::class, 'markAwaitingConfirmation'])->name('missions.mark-awaiting-confirmation');
    Route::patch('/missions/{mission}/confirm-completion', [MissionController::class, 'confirmCompletion'])->name('missions.confirm-completion');
    Route::patch('/missions/{mission}/mark-paid', [MissionController::class, 'markPaid'])->name('missions.mark-paid');
    Route::patch('/missions/{mission}/cancel', [MissionController::class, 'cancel'])->name('missions.cancel');

    // Reviews
    Route::post('/missions/{mission}/review', [ReviewController::class, 'store'])->name('reviews.store');
    Route::patch('/reviews/{review}', [ReviewController::class, 'update'])->name('reviews.update');

    // Conversations & Messages
    Route::get('/conversations', [ConversationController::class, 'index'])->name('conversations.index');
    Route::get('/conversations/{conversation}', [ConversationController::class, 'show'])->name('conversations.show');
    Route::post('/conversations/start', [ConversationController::class, 'startOrFind'])->name('conversations.start-or-find');
    Route::post('/conversations/{conversation}/messages', [MessageController::class, 'store'])->name('messages.store');

    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index'])->name('notifications.index');
    Route::patch('/notifications/{notification}/mark-as-read', [NotificationController::class, 'markAsRead'])->name('notifications.mark-as-read');
    Route::patch('/notifications/mark-all-as-read', [NotificationController::class, 'markAllAsRead'])->name('notifications.mark-all-as-read');
});
REFEOF1

cat > "README_STUBS.md" << 'MDEOF'
# Fichiers STUB temporaires — à lire avant de les utiliser

Ces fichiers ne remplacent PAS le travail de Victorius et Mme Titilola.
Ils servent uniquement à débloquer ton développement/tests en attendant
qu'ils livrent leurs vraies tables.

## Fichiers concernés

- `2026_08_20_090000_add_est_client_et_est_prestataire_to_users_table.php`
- `2026_08_20_090100_create_provider_profiles_table.php`
- `2026_08_20_090200_create_service_categories_table.php`
- `2026_08_20_090300_create_zones_table.php`
- `app/Models/ProviderProfile.php`
- `app/Models/ServiceCategory.php`
- `app/Models/Zone.php`
- `database/factories/ProviderProfileFactory.php`
- `database/factories/ServiceCategoryFactory.php`
- `database/factories/ZoneFactory.php`
- `database/seeders/ScenarioCarreleurTankpeSeeder.php` (peut être gardé,
  il n'a pas besoin d'être supprimé — juste adapté si les noms de colonnes
  changent)

## Comment les utiliser maintenant

```bash
php artisan migrate
php artisan db:seed --class=ScenarioCarreleurTankpeSeeder
```

Ça te crée un client, un prestataire, une ServiceRequest publiée et un
Proposal en attente — de quoi tester tout ton pôle (accepter le devis,
créer la mission, la terminer, laisser un avis...) sans aucune vraie
donnée de Victorius/Titilola.

## Quand Victorius/Titilola livrent leur vrai travail

1. Supprime les 4 migrations stub listées ci-dessus (`database/migrations/`)
2. Supprime les 3 models stub (`app/Models/`)
3. Supprime les 3 factories stub (`database/factories/`)
4. `php artisan migrate:fresh` pour repartir sur les vraies tables
5. Vérifie que la colonne `provider_profiles.user_id` existe bien chez
   Victorius avec ce nom exact — sinon, ajuste les relations Eloquent
   dans `ServiceRequest`, `Proposal`, `Mission`, `Conversation`, `Review`
   (partout où `->providerProfile->user_id` est utilisé)
6. Adapte `ScenarioCarreleurTankpeSeeder` si les noms de colonnes
   diffèrent, sinon garde-le tel quel — utile pour les démos/tests
MDEOF

echo ""
echo "✅ Backend (Services + Controllers Inertia + Api/V1 + Resources) + Frontend créés."
echo "✅ routes/api_abed.php créé DIRECTEMENT — ajoute juste dans routes/api.php :"
echo "   require __DIR__.'/api_abed.php';"
echo "⚠️  routes_pole_abed.php (racine) reste à fusionner MANUELLEMENT dans routes/web.php."
echo "Ensuite : composer dump-autoload && php artisan migrate && php artisan db:seed --class=ScenarioCarreleurTankpeSeeder"
echo "Front : npm run build"