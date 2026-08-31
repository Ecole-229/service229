#!/bin/bash
# Script de mise en place du pôle "Demandes & Mise en relation" — Service229
# À lancer depuis LA RACINE du projet Laravel (là où se trouve artisan)
set -e

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
            $table->string('nom');
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
            $table->string('nom');
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
use App\Models\ProviderProfile;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ConversationController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();

        $conversations = Conversation::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['client', 'providerProfile', 'serviceRequest'])
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

        $conversation->load(['client', 'providerProfile', 'serviceRequest', 'messages.sender']);

        // Marquer comme lus les messages de l'autre personne
        $conversation->messages()
            ->whereNull('read_at')
            ->where('sender_id', '!=', $request->user()->id)
            ->update(['read_at' => now()]);

        return Inertia::render('Conversations/Show', [
            'conversation' => $conversation,
        ]);
    }

    /**
     * Démarre (ou récupère) le fil unique client/prestataire — "discuter avant
     * de faire une demande". Un seul fil possible par duo (voir migration).
     */
    public function startOrFind(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'provider_profile_id' => ['required', 'exists:provider_profiles,id'],
        ]);

        $conversation = Conversation::firstOrCreate([
            'client_id' => $request->user()->id,
            'provider_profile_id' => $validated['provider_profile_id'],
        ]);

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

use App\Events\MessageSent;
use App\Http\Requests\StoreMessageRequest;
use App\Models\Conversation;
use App\Models\Message;

class MessageController extends Controller
{
    public function store(StoreMessageRequest $request, Conversation $conversation)
    {
        $this->authorize('sendMessage', $conversation);

        $message = Message::create([
            ...$request->validated(),
            'conversation_id' => $conversation->id,
            'sender_id' => $request->user()->id,
        ]);

        // Fait remonter la conversation en haut de la liste (tri par updated_at)
        $conversation->touch();

        MessageSent::dispatch($message);

        return back();
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

use App\Events\MissionCompleted;
use App\Models\Mission;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class MissionController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();

        $missions = Mission::query()
            ->where('client_id', $user->id)
            ->orWhereHas('providerProfile', fn ($q) => $q->where('user_id', $user->id))
            ->with(['serviceRequest', 'proposal', 'client', 'providerProfile', 'review'])
            ->latest()
            ->paginate(10);

        return Inertia::render('Missions/Index', [
            'missions' => $missions,
        ]);
    }

    public function show(Request $request, Mission $mission): Response
    {
        $this->authorize('view', $mission);

        $mission->load(['serviceRequest', 'proposal', 'client', 'providerProfile', 'review']);

        return Inertia::render('Missions/Show', [
            'mission' => $mission,
        ]);
    }

    /**
     * Le prestataire démarre la mission.
     */
    public function start(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('start', $mission);

        $mission->update(['status' => Mission::STATUS_IN_PROGRESS]);

        return back()->with('success', 'Mission démarrée.');
    }

    /**
     * Le prestataire signale que le travail est terminé de son côté.
     */
    public function markAwaitingConfirmation(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('markAwaitingConfirmation', $mission);

        $mission->update(['status' => Mission::STATUS_AWAITING_CONFIRMATION]);

        return back()->with('success', 'En attente de confirmation du client.');
    }

    /**
     * Le client confirme que le travail est bien terminé.
     */
    public function confirmCompletion(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('confirmCompletion', $mission);

        $mission->update(['status' => Mission::STATUS_COMPLETED]);

        $mission->serviceRequest->update(['status' => \App\Models\ServiceRequest::STATUS_CLOSED]);

        MissionCompleted::dispatch($mission->fresh());

        return back()->with('success', 'Mission terminée. Vous pouvez laisser un avis.');
    }

    /**
     * Le client indique que le paiement (hors plateforme) a bien été effectué.
     */
    public function markPaid(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('markPaid', $mission);

        $mission->update(['paiementEffectue' => true]);

        return back()->with('success', 'Paiement marqué comme effectué.');
    }

    /**
     * Annulation par le client ou le prestataire, tant que la mission
     * n'est pas déjà terminée.
     */
    public function cancel(Request $request, Mission $mission): RedirectResponse
    {
        $this->authorize('cancel', $mission);

        $mission->update(['status' => Mission::STATUS_CANCELLED]);

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

    private function isParticipant(User $user, Mission $mission): bool
    {
        return $mission->client_id === $user->id
            || $mission->providerProfile->user_id === $user->id;
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
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class NotificationController extends Controller
{
    public function index(Request $request): Response
    {
        $notifications = Notification::query()
            ->where('user_id', $request->user()->id)
            ->latest()
            ->paginate(20);

        return Inertia::render('Notifications/Index', [
            'notifications' => $notifications,
        ]);
    }

    public function markAsRead(Request $request, Notification $notification): RedirectResponse
    {
        abort_unless($notification->user_id === $request->user()->id, 403);

        $notification->update(['lu' => true]);

        return back();
    }

    public function markAllAsRead(Request $request): RedirectResponse
    {
        Notification::where('user_id', $request->user()->id)
            ->where('lu', false)
            ->update(['lu' => true]);

        return back();
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

use App\Events\ProposalAccepted as ProposalAcceptedEvent;
use App\Events\ProposalCreated;
use App\Http\Requests\StoreProposalRequest;
use App\Models\Mission;
use App\Models\Proposal;
use App\Models\ServiceRequest;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class ProposalController extends Controller
{
    /**
     * Un prestataire envoie un devis sur une demande ouverte (Mode 2).
     * Passe la ServiceRequest de "published" à "matched" au premier devis reçu.
     */
    public function store(StoreProposalRequest $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        abort_unless($serviceRequest->isOpenToProposals(), 422, 'Cette demande n\'accepte plus de devis.');

        $validated = $request->validated();

        $providerProfileId = $request->user()->providerProfile->id;

        $proposal = Proposal::create([
            ...$validated,
            'service_request_id' => $serviceRequest->id,
            'provider_profile_id' => $providerProfileId,
            'status' => Proposal::STATUS_PENDING,
        ]);

        if ($serviceRequest->status === ServiceRequest::STATUS_PUBLISHED) {
            $serviceRequest->update(['status' => ServiceRequest::STATUS_MATCHED]);
        }

        ProposalCreated::dispatch($proposal);

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', 'Devis envoyé.');
    }

    /**
     * Le client accepte un devis : le devis passe à "accepted", tous les
     * autres devis pending de la même demande sont automatiquement "rejected",
     * la demande passe à "assigned", et une Mission est créée.
     */
    public function accept(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $serviceRequest = $proposal->serviceRequest;
        $mission = null;

        \DB::transaction(function () use ($proposal, $serviceRequest, &$mission) {
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

        ProposalAcceptedEvent::dispatch($proposal->fresh());

        return redirect()
            ->route('missions.show', $mission)
            ->with('success', 'Devis accepté, mission créée.');
    }

    /**
     * Le client refuse un devis précis (sans accepter les autres pour autant).
     */
    public function reject(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('acceptOrReject', $proposal);

        $proposal->update(['status' => Proposal::STATUS_REJECTED]);

        return back()->with('success', 'Devis refusé.');
    }

    /**
     * Le prestataire retire lui-même son devis.
     */
    public function withdraw(Request $request, Proposal $proposal): RedirectResponse
    {
        $this->authorize('withdraw', $proposal);

        $proposal->update(['status' => Proposal::STATUS_WITHDRAWN]);

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

mkdir -p "app/Models"
cat > "app/Models/ProviderProfile.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderProfile extends Model
{
    protected $fillable = [
        'user_id',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
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
        $carrelage = ServiceCategory::firstOrCreate(['nom' => 'Carrelage']);
        $tankpe = Zone::firstOrCreate(['nom' => 'Tankpè']);

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

mkdir -p "app/Models"
cat > "app/Models/ServiceCategory.php" << 'PHPEOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ServiceCategory extends Model
{
    protected $fillable = [
        'nom',
    ];
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
            'nom' => fake()->randomElement([
                'Carrelage', 'Plomberie', 'Électricité', 'Peinture', 'Menuiserie',
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
use App\Models\ServiceRequestPhoto;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;

class ServiceRequestController extends Controller
{
    /**
     * Liste des demandes du client connecté (son "espace demandes").
     */
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

    /**
     * Détail d'une demande (devis reçus, conversation, statut...).
     */
    public function show(Request $request, ServiceRequest $serviceRequest): Response
    {
        $this->authorize('view', $serviceRequest);

        $serviceRequest->load([
            'serviceCategory',
            'zone',
            'providerProfile',
            'proposals.providerProfile',
            'mission',
            'conversation.messages',
            'photos',
        ]);

        return Inertia::render('ServiceRequests/Show', [
            'serviceRequest' => $serviceRequest,
        ]);
    }

    /**
     * Création d'une demande — couvre les deux modes (section 2.2 du document) :
     * - Mode 1 : contact direct (provider_profile_id renseigné) -> statut "assigned" direct
     * - Mode 2 : besoin ouvert (provider_profile_id absent) -> statut "published"
     */
    public function store(StoreServiceRequestRequest $request): RedirectResponse
    {
        $validated = $request->validated();
        $photos = $validated['photos'] ?? [];
        unset($validated['photos']);

        $isDirectContact = ! empty($validated['provider_profile_id']);

        // "Enregistrer en brouillon" vs "Publier ma demande" (deux boutons de la maquette)
        $status = match (true) {
            $isDirectContact => ServiceRequest::STATUS_ASSIGNED,
            $request->boolean('as_draft') => ServiceRequest::STATUS_DRAFT,
            default => ServiceRequest::STATUS_PUBLISHED,
        };

        $serviceRequest = ServiceRequest::create([
            ...$validated,
            'client_id' => $request->user()->id,
            'status' => $status,
        ]);

        foreach ($photos as $photo) {
            $path = $photo->store('service-requests', 'public');

            ServiceRequestPhoto::create([
                'service_request_id' => $serviceRequest->id,
                'chemin_fichier' => $path,
            ]);
        }

        return redirect()
            ->route('service-requests.show', $serviceRequest)
            ->with('success', 'Demande créée avec succès.');
    }

    /**
     * Annulation d'une demande par le client — uniquement si elle n'est pas
     * déjà engagée sur une mission (status assigned/matched restent annulables,
     * mais pas une demande déjà "closed").
     */
    public function cancel(Request $request, ServiceRequest $serviceRequest): RedirectResponse
    {
        $this->authorize('cancel', $serviceRequest);

        $serviceRequest->update(['status' => ServiceRequest::STATUS_CANCELLED]);

        return redirect()
            ->route('service-requests.index')
            ->with('success', 'Demande annulée.');
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
        return $serviceRequest->client_id === $user->id;
    }

    public function cancel(User $user, ServiceRequest $serviceRequest): bool
    {
        return $serviceRequest->client_id === $user->id
            && $serviceRequest->status !== ServiceRequest::STATUS_CLOSED;
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
    protected $fillable = [
        'nom',
    ];
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
            'nom' => fake()->randomElement([
                'Tankpè', 'Calavi', 'Godomey', 'Cococodji', 'Cotonou',
            ]),
        ];
    }
}
PHPEOF

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

echo "✅ Tous les fichiers du pôle Demandes & Mise en relation ont été créés."
echo "Pense à lancer : php artisan migrate && php artisan db:seed --class=ScenarioCarreleurTankpeSeeder"