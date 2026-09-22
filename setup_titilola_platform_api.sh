#!/usr/bin/env bash
set -Eeuo pipefail

# =============================================================================
# Service229 — Automatisation du pôle Titilola
# Fichier à placer à la RACINE du projet Laravel (au même niveau que artisan).
#
# Objectif :
#   - sécuriser l'intégration du socle API REST v1 ;
#   - installer/configurer Sanctum si nécessaire ;
#   - créer les endpoints API Titilola sans recréer les modèles/migrations Abed ;
#   - créer les Resources, contrôleurs et tests du référentiel ;
#   - créer les endpoints ProviderProfile sûrs (lecture + sync services/zones) ;
#   - créer les endpoints Admin du référentiel + dashboard API ;
#   - générer une documentation de contrat ;
#   - lancer les contrôles de qualité non destructifs.
#
# IMPORTANT :
#   - le script NE FAIT PAS "migrate:fresh" ;
#   - le script NE SUPPRIME PAS de données ;
#   - le script NE RECRÉE PAS ServiceCategory, Service, Zone, ProviderProfile ;
#   - le script s'arrête si le socle partagé attendu n'est pas présent ;
#   - la création/validation complète d'un ProviderProfile reste à adapter au
#     schéma réel si celui-ci contient des champs obligatoires spécifiques.
#
# Windows :
#   Exécuter ce fichier avec Git Bash ou WSL, PAS directement dans PowerShell.
#
# Usage :
#   chmod +x setup_titilola_platform_api.sh
#   ./setup_titilola_platform_api.sh
#
# Options facultatives :
#   SKIP_INSTALL=1 ./setup_titilola_platform_api.sh
#   SKIP_TESTS=1   ./setup_titilola_platform_api.sh
#   ALLOW_DIRTY=1  ./setup_titilola_platform_api.sh
# =============================================================================

PROJECT_NAME="Service229"
API_PREFIX="v1"

green='\033[0;32m'
yellow='\033[1;33m'
red='\033[0;31m'
blue='\033[0;34m'
nc='\033[0m'

info()  { printf "${blue}[INFO]${nc} %s\n" "$*"; }
ok()    { printf "${green}[OK]${nc} %s\n" "$*"; }
warn()  { printf "${yellow}[WARN]${nc} %s\n" "$*"; }
fail()  { printf "${red}[ERREUR]${nc} %s\n" "$*" >&2; exit 1; }

on_error() {
    local exit_code=$?
    printf "\n${red}[ECHEC]${nc} Le script s'est arrêté à la ligne %s (code %s).\n" "${BASH_LINENO[0]}" "$exit_code" >&2
    printf "Corrigez l'erreur puis relancez le script : il est conçu pour être rejouable.\n" >&2
    exit "$exit_code"
}
trap on_error ERR

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "Commande manquante : $1"
}

write_if_missing() {
    local target="$1"
    local content="$2"
    if [[ -e "$target" ]]; then
        warn "Conservé (déjà présent) : $target"
    else
        mkdir -p "$(dirname "$target")"
        printf "%s" "$content" > "$target"
        ok "Créé : $target"
    fi
}

append_line_once() {
    local target="$1"
    local line="$2"
    grep -Fqx "$line" "$target" 2>/dev/null || {
        printf "\n%s\n" "$line" >> "$target"
        ok "Ajouté dans $target : $line"
    }
}

# -----------------------------------------------------------------------------
# 0. PRÉ-VÉRIFICATIONS
# -----------------------------------------------------------------------------
[[ -f artisan ]] || fail "artisan introuvable. Placez ce fichier à la racine du projet Laravel."
[[ -f composer.json ]] || fail "composer.json introuvable."
[[ -d app ]] || fail "Dossier app/ introuvable."
[[ -d database/migrations ]] || fail "Dossier database/migrations introuvable."

require_cmd git
require_cmd php
require_cmd composer
require_cmd node
require_cmd npm

CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || true)"
[[ -n "$CURRENT_BRANCH" ]] || fail "Impossible de déterminer la branche Git."

if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    fail "Vous êtes sur '$CURRENT_BRANCH'. Travaillez d'abord sur develop puis feature/titilola-platform-api."
fi

info "Branche actuelle : $CURRENT_BRANCH"

if [[ "${ALLOW_DIRTY:-0}" != "1" ]] && [[ -n "$(git status --porcelain)" ]]; then
    fail "La copie de travail n'est pas propre. Committez/stashez vos changements, ou relancez avec ALLOW_DIRTY=1."
fi

# Le socle partagé attendu après intégration d'Abed.
REQUIRED_MODELS=(
    "app/Models/ServiceCategory.php"
    "app/Models/Service.php"
    "app/Models/Zone.php"
    "app/Models/ProviderProfile.php"
    "app/Models/User.php"
)

for f in "${REQUIRED_MODELS[@]}"; do
    [[ -f "$f" ]] || fail "Socle partagé incomplet : $f est absent. Intégrez d'abord la branche Abed dans develop."
done

grep -Rqs "create_service_categories" database/migrations || \
    grep -Rqs "Schema::create('service_categories'" database/migrations || \
    fail "Migration service_categories introuvable."

grep -Rqs "Schema::create('services'" database/migrations || \
    fail "Migration services introuvable."

grep -Rqs "Schema::create('zones'" database/migrations || \
    fail "Migration zones introuvable."

grep -Rqs "Schema::create('provider_profiles'" database/migrations || \
    fail "Migration provider_profiles introuvable."

grep -Rqs "Schema::create('provider_services'" database/migrations || \
    fail "Migration provider_services introuvable."

grep -Rqs "Schema::create('provider_zones'" database/migrations || \
    fail "Migration provider_zones introuvable."

ok "Socle partagé détecté."

# -----------------------------------------------------------------------------
# 1. DÉPENDANCES
# -----------------------------------------------------------------------------
if [[ "${SKIP_INSTALL:-0}" != "1" ]]; then
    if [[ ! -d vendor ]]; then
        info "Installation des dépendances Composer..."
        composer install
    else
        ok "vendor/ existe déjà."
    fi

    if [[ ! -d node_modules ]]; then
        info "Installation des dépendances npm..."
        npm install
    else
        ok "node_modules/ existe déjà."
    fi
else
    warn "Installation des dépendances ignorée (SKIP_INSTALL=1)."
fi

# -----------------------------------------------------------------------------
# 2. SANCTUM + ROUTE API
# -----------------------------------------------------------------------------
if ! composer show laravel/sanctum >/dev/null 2>&1; then
    info "Laravel Sanctum absent : exécution de php artisan install:api..."
    php artisan install:api
else
    ok "Laravel Sanctum est déjà installé."
fi

if [[ ! -f routes/api.php ]]; then
    cat > routes/api.php <<'PHP'
<?php

use Illuminate\Support\Facades\Route;

Route::get('/health', fn () => response()->json([
    'success' => true,
    'message' => 'API Service229 opérationnelle.',
]));
PHP
    ok "Créé : routes/api.php"
fi

# Vérifier que bootstrap/app.php référence l'API. install:api le fait normalement.
if ! grep -q "routes/api.php" bootstrap/app.php && ! grep -q "api: __DIR__.*api.php" bootstrap/app.php; then
    warn "bootstrap/app.php ne semble pas charger routes/api.php."
    warn "Laravel install:api devrait normalement l'ajouter. Vérifiez ce fichier avant le merge final."
fi

# -----------------------------------------------------------------------------
# 3. STRUCTURE TITILOLA
# -----------------------------------------------------------------------------
mkdir -p \
    app/Http/Controllers/Api/V1/Admin \
    app/Http/Controllers/Api/V1 \
    app/Http/Resources \
    app/Support \
    docs \
    tests/Feature/Api

# -----------------------------------------------------------------------------
# 4. TRAIT DE RÉPONSE JSON COMMUNE
# -----------------------------------------------------------------------------
write_if_missing "app/Support/ApiResponse.php" '<?php

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
'

# -----------------------------------------------------------------------------
# 5. API RESOURCES
# -----------------------------------------------------------------------------
write_if_missing "app/Http/Resources/ServiceCategoryResource.php" '<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceCategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            "id" => $this->id,
            "name" => $this->name,
            "services" => ServiceResource::collection($this->whenLoaded("services")),
        ];
    }
}
'

write_if_missing "app/Http/Resources/ServiceResource.php" '<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            "id" => $this->id,
            "category_id" => $this->category_id,
            "name" => $this->name,
            "category" => new ServiceCategoryResource($this->whenLoaded("category")),
        ];
    }
}
'

write_if_missing "app/Http/Resources/ZoneResource.php" '<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ZoneResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            "id" => $this->id,
            "name" => $this->name,
        ];
    }
}
'

write_if_missing "app/Http/Resources/ProviderProfileResource.php" '<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProviderProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            "id" => $this->id,
            "user_id" => $this->user_id,
            "user" => $this->whenLoaded("user", function () {
                return [
                    "id" => $this->user->id,
                    "name" => $this->user->name,
                ];
            }),
            "services" => ServiceResource::collection($this->whenLoaded("services")),
            "zones" => ZoneResource::collection($this->whenLoaded("zones")),
        ];
    }
}
'

# -----------------------------------------------------------------------------
# 6. CONTRÔLEURS PUBLICS DU RÉFÉRENTIEL
# -----------------------------------------------------------------------------
write_if_missing "app/Http/Controllers/Api/V1/ServiceCategoryController.php" '<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceCategoryResource;
use App\Models\ServiceCategory;
use App\Support\ApiResponse;

class ServiceCategoryController extends Controller
{
    use ApiResponse;

    public function index()
    {
        $query = ServiceCategory::query()->orderBy("name");

        if (method_exists(ServiceCategory::class, "services")) {
            $query->with("services");
        }

        return $this->success(
            ServiceCategoryResource::collection($query->get())->resolve(),
            "Catégories récupérées avec succès."
        );
    }

    public function show(ServiceCategory $category)
    {
        if (method_exists($category, "services")) {
            $category->load("services");
        }

        return $this->success(
            (new ServiceCategoryResource($category))->resolve(),
            "Catégorie récupérée avec succès."
        );
    }
}
'

write_if_missing "app/Http/Controllers/Api/V1/ServiceController.php" '<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceResource;
use App\Models\Service;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class ServiceController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $query = Service::query()->orderBy("name");

        if (method_exists(Service::class, "category")) {
            $query->with("category");
        }

        $query->when(
            $request->filled("category_id"),
            fn ($q) => $q->where("category_id", $request->integer("category_id"))
        );

        $query->when(
            $request->filled("q"),
            fn ($q) => $q->where("name", "like", "%".$request->string("q")."%")
        );

        return $this->success(
            ServiceResource::collection($query->get())->resolve(),
            "Services récupérés avec succès."
        );
    }

    public function show(Service $service)
    {
        if (method_exists($service, "category")) {
            $service->load("category");
        }

        return $this->success(
            (new ServiceResource($service))->resolve(),
            "Service récupéré avec succès."
        );
    }
}
'

write_if_missing "app/Http/Controllers/Api/V1/ZoneController.php" '<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ZoneResource;
use App\Models\Zone;
use App\Support\ApiResponse;

class ZoneController extends Controller
{
    use ApiResponse;

    public function index()
    {
        return $this->success(
            ZoneResource::collection(Zone::query()->orderBy("name")->get())->resolve(),
            "Zones récupérées avec succès."
        );
    }

    public function show(Zone $zone)
    {
        return $this->success(
            (new ZoneResource($zone))->resolve(),
            "Zone récupérée avec succès."
        );
    }
}
'

# -----------------------------------------------------------------------------
# 7. PROVIDERS : LECTURE PUBLIQUE + PROFIL COURANT + SYNC OFFRE/ZONES
# -----------------------------------------------------------------------------
write_if_missing "app/Http/Controllers/Api/V1/ProviderController.php" '<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProviderProfileResource;
use App\Models\ProviderProfile;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class ProviderController extends Controller
{
    use ApiResponse;

    private function relations(): array
    {
        return array_values(array_filter(
            ["user", "services", "zones"],
            fn (string $relation) => method_exists(ProviderProfile::class, $relation)
        ));
    }

    public function index(Request $request)
    {
        $query = ProviderProfile::query()->with($this->relations());

        if ($request->filled("service_id") && method_exists(ProviderProfile::class, "services")) {
            $serviceId = $request->integer("service_id");
            $query->whereHas("services", fn ($q) => $q->where("services.id", $serviceId));
        }

        if ($request->filled("zone_id") && method_exists(ProviderProfile::class, "zones")) {
            $zoneId = $request->integer("zone_id");
            $query->whereHas("zones", fn ($q) => $q->where("zones.id", $zoneId));
        }

        $providers = $query->paginate(15);

        return $this->paginated(
            $providers,
            ProviderProfileResource::collection($providers->getCollection())->resolve(),
            "Prestataires récupérés avec succès."
        );
    }

    public function show(ProviderProfile $provider)
    {
        $provider->load($this->relations());

        return $this->success(
            (new ProviderProfileResource($provider))->resolve(),
            "Prestataire récupéré avec succès."
        );
    }
}
'

write_if_missing "app/Http/Controllers/Api/V1/ProviderProfileController.php" '<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProviderProfileResource;
use App\Models\ProviderProfile;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class ProviderProfileController extends Controller
{
    use ApiResponse;

    private function currentProfile(Request $request): ProviderProfile
    {
        return ProviderProfile::query()
            ->where("user_id", $request->user()->id)
            ->firstOrFail();
    }

    private function loadSafeRelations(ProviderProfile $profile): ProviderProfile
    {
        $relations = array_values(array_filter(
            ["user", "services", "zones"],
            fn (string $relation) => method_exists(ProviderProfile::class, $relation)
        ));

        return $profile->load($relations);
    }

    public function show(Request $request)
    {
        $profile = $this->loadSafeRelations($this->currentProfile($request));

        return $this->success(
            (new ProviderProfileResource($profile))->resolve(),
            "Profil prestataire récupéré avec succès."
        );
    }

    public function syncServices(Request $request)
    {
        $validated = $request->validate([
            "service_ids" => ["required", "array"],
            "service_ids.*" => ["integer", "distinct", "exists:services,id"],
        ]);

        $profile = $this->currentProfile($request);

        if (! method_exists($profile, "services")) {
            return $this->error(
                "La relation ProviderProfile::services() doit être définie avant cette opération.",
                409
            );
        }

        $profile->services()->sync($validated["service_ids"]);

        return $this->success(
            (new ProviderProfileResource($this->loadSafeRelations($profile)))->resolve(),
            "Services du prestataire mis à jour."
        );
    }

    public function syncZones(Request $request)
    {
        $validated = $request->validate([
            "zone_ids" => ["required", "array"],
            "zone_ids.*" => ["integer", "distinct", "exists:zones,id"],
        ]);

        $profile = $this->currentProfile($request);

        if (! method_exists($profile, "zones")) {
            return $this->error(
                "La relation ProviderProfile::zones() doit être définie avant cette opération.",
                409
            );
        }

        $profile->zones()->sync($validated["zone_ids"]);

        return $this->success(
            (new ProviderProfileResource($this->loadSafeRelations($profile)))->resolve(),
            "Zones du prestataire mises à jour."
        );
    }
}
'

# -----------------------------------------------------------------------------
# 8. ADMIN API : CRUD RÉFÉRENTIEL
# -----------------------------------------------------------------------------
write_if_missing "app/Http/Controllers/Api/V1/Admin/ReferenceController.php" '<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceCategoryResource;
use App\Http\Resources\ServiceResource;
use App\Http\Resources\ZoneResource;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\Zone;
use App\Support\ApiResponse;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;

class ReferenceController extends Controller
{
    use ApiResponse;

    public function storeCategory(Request $request)
    {
        $validated = $request->validate([
            "name" => ["required", "string", "max:255", "unique:service_categories,name"],
        ]);

        $category = ServiceCategory::create($validated);

        return $this->success(
            (new ServiceCategoryResource($category))->resolve(),
            "Catégorie créée.",
            201
        );
    }

    public function updateCategory(Request $request, ServiceCategory $category)
    {
        $validated = $request->validate([
            "name" => [
                "required", "string", "max:255",
                "unique:service_categories,name,".$category->id,
            ],
        ]);

        $category->update($validated);

        return $this->success(
            (new ServiceCategoryResource($category))->resolve(),
            "Catégorie mise à jour."
        );
    }

    public function destroyCategory(ServiceCategory $category)
    {
        try {
            $category->delete();
        } catch (QueryException $e) {
            return $this->error(
                "Impossible de supprimer cette catégorie car elle est encore utilisée.",
                409
            );
        }

        return $this->success(null, "Catégorie supprimée.");
    }

    public function storeService(Request $request)
    {
        $validated = $request->validate([
            "category_id" => ["required", "integer", "exists:service_categories,id"],
            "name" => ["required", "string", "max:255"],
        ]);

        $service = Service::create($validated);

        return $this->success(
            (new ServiceResource($service->load("category")))->resolve(),
            "Service créé.",
            201
        );
    }

    public function updateService(Request $request, Service $service)
    {
        $validated = $request->validate([
            "category_id" => ["required", "integer", "exists:service_categories,id"],
            "name" => ["required", "string", "max:255"],
        ]);

        $service->update($validated);

        return $this->success(
            (new ServiceResource($service->load("category")))->resolve(),
            "Service mis à jour."
        );
    }

    public function destroyService(Service $service)
    {
        try {
            $service->delete();
        } catch (QueryException $e) {
            return $this->error(
                "Impossible de supprimer ce service car il est encore utilisé.",
                409
            );
        }

        return $this->success(null, "Service supprimé.");
    }

    public function storeZone(Request $request)
    {
        $validated = $request->validate([
            "name" => ["required", "string", "max:255", "unique:zones,name"],
        ]);

        $zone = Zone::create($validated);

        return $this->success(
            (new ZoneResource($zone))->resolve(),
            "Zone créée.",
            201
        );
    }

    public function updateZone(Request $request, Zone $zone)
    {
        $validated = $request->validate([
            "name" => [
                "required", "string", "max:255",
                "unique:zones,name,".$zone->id,
            ],
        ]);

        $zone->update($validated);

        return $this->success(
            (new ZoneResource($zone))->resolve(),
            "Zone mise à jour."
        );
    }

    public function destroyZone(Zone $zone)
    {
        try {
            $zone->delete();
        } catch (QueryException $e) {
            return $this->error(
                "Impossible de supprimer cette zone car elle est encore utilisée.",
                409
            );
        }

        return $this->success(null, "Zone supprimée.");
    }
}
'

# -----------------------------------------------------------------------------
# 9. ADMIN API : DASHBOARD
# -----------------------------------------------------------------------------
write_if_missing "app/Http/Controllers/Api/V1/Admin/DashboardController.php" '<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\ProviderProfile;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use App\Models\Zone;
use App\Support\ApiResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    use ApiResponse;

    public function __invoke()
    {
        $countTable = static function (string $table): int {
            return Schema::hasTable($table) ? DB::table($table)->count() : 0;
        };

        return $this->success([
            "users" => User::query()->count(),
            "providers" => ProviderProfile::query()->count(),
            "categories" => ServiceCategory::query()->count(),
            "services" => Service::query()->count(),
            "zones" => Zone::query()->count(),
            "service_requests" => $countTable("service_requests"),
            "proposals" => $countTable("proposals"),
            "missions" => $countTable("missions"),
            "reports" => $countTable("reports"),
            "activity_logs" => $countTable("activity_logs"),
        ], "Indicateurs administrateur récupérés.");
    }
}
'

# -----------------------------------------------------------------------------
# 10. ROUTES TITILOLA
# -----------------------------------------------------------------------------
write_if_missing "routes/api_titilola.php" '<?php

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
'

append_line_once "routes/api.php" "require __DIR__.'/api_titilola.php';"

# -----------------------------------------------------------------------------
# 11. TESTS API RÉFÉRENTIEL
# -----------------------------------------------------------------------------
write_if_missing "tests/Feature/Api/TitilolaReferenceApiTest.php" '<?php

namespace Tests\Feature\Api;

use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\Zone;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TitilolaReferenceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_categories_endpoint_returns_categories(): void
    {
        ServiceCategory::query()->create(["name" => "Carrelage"]);

        $this->getJson("/api/v1/categories")
            ->assertOk()
            ->assertJsonPath("success", true)
            ->assertJsonFragment(["name" => "Carrelage"]);
    }

    public function test_services_can_be_filtered_by_category(): void
    {
        $category = ServiceCategory::query()->create(["name" => "Bâtiment"]);

        Service::query()->create([
            "category_id" => $category->id,
            "name" => "Carrelage",
        ]);

        $this->getJson("/api/v1/services?category_id=".$category->id)
            ->assertOk()
            ->assertJsonPath("success", true)
            ->assertJsonFragment(["name" => "Carrelage"]);
    }

    public function test_zones_endpoint_returns_zones(): void
    {
        Zone::query()->create(["name" => "Tankpè"]);

        $this->getJson("/api/v1/zones")
            ->assertOk()
            ->assertJsonPath("success", true)
            ->assertJsonFragment(["name" => "Tankpè"]);
    }

    public function test_provider_profile_requires_authentication(): void
    {
        $this->getJson("/api/v1/provider-profile")
            ->assertUnauthorized();
    }

    public function test_admin_dashboard_requires_authentication(): void
    {
        $this->getJson("/api/v1/admin/dashboard")
            ->assertUnauthorized();
    }
}
'

# -----------------------------------------------------------------------------
# 12. DOCUMENTATION DU CONTRAT TITILOLA
# -----------------------------------------------------------------------------
write_if_missing "docs/TITILOLA_API_CONTRACT.md" '# Service229 — Contrat API du pôle Titilola

## Architecture

Laravel + Vue 3 + Inertia + API REST `/api/v1` + Sanctum + MySQL.

Les pages restent gérées par Inertia/Vue. L API sert les données dynamiques et
les opérations métier. Le code API ne doit pas recréer les modèles et migrations
déjà intégrés par Abed.

## Responsabilité Titilola

- ServiceCategory
- Service
- Zone
- ProviderProfile (supervision / services / zones)
- provider_services
- provider_zones
- administration
- socle API
- sécurité API
- ActivityLog / monitoring / infrastructure

## Endpoints créés automatiquement

### Public

- GET `/api/v1/categories`
- GET `/api/v1/categories/{category}`
- GET `/api/v1/services`
- GET `/api/v1/services/{service}`
- GET `/api/v1/zones`
- GET `/api/v1/zones/{zone}`
- GET `/api/v1/providers`
- GET `/api/v1/providers/{provider}`

### Prestataire authentifié

- GET `/api/v1/provider-profile`
- PUT `/api/v1/provider-profile/services`
- PUT `/api/v1/provider-profile/zones`

### Admin

- GET `/api/v1/admin/dashboard`
- POST/PUT/DELETE `/api/v1/admin/categories`
- POST/PUT/DELETE `/api/v1/admin/services`
- POST/PUT/DELETE `/api/v1/admin/zones`

## Points volontairement NON automatisés

Ces éléments dépendent du schéma exact et doivent être validés avant codage :

1. création/activation complète d un ProviderProfile si la table comporte des
   champs obligatoires supplémentaires ;
2. champ exact de validation administrative du ProviderProfile ;
3. endpoints Reports/Disputes si leur contrat métier est encore en évolution ;
4. modification destructive d une migration existante ;
5. `migrate:fresh`, qui ne doit jamais être lancé automatiquement.

## Contrat métier partagé

- `users.estClient` : capacité Client
- `users.estPrestataire` : capacité Prestataire
- `roles/role_user` : autorisations spéciales, notamment Admin
- `services.category_id` -> `service_categories.id`
- `provider_services` relie ProviderProfile et Service
- `provider_zones` relie ProviderProfile et Zone

## Prochaine validation commune Titilola + Abed

Valider le scénario :

Client -> Carrelage + Tankpè -> Providers -> ServiceRequest -> Proposal ->
Mission -> Conversation/Message -> Notification -> Review -> Dashboard Admin.
'

# -----------------------------------------------------------------------------
# 13. CONTRÔLES NON DESTRUCTIFS
# -----------------------------------------------------------------------------
info "Nettoyage du cache de configuration..."
php artisan config:clear || warn "config:clear a échoué ; vérifiez le .env."

info "Vérification syntaxique PHP des fichiers générés..."
PHP_FILES=(
    app/Support/ApiResponse.php
    app/Http/Resources/ServiceCategoryResource.php
    app/Http/Resources/ServiceResource.php
    app/Http/Resources/ZoneResource.php
    app/Http/Resources/ProviderProfileResource.php
    app/Http/Controllers/Api/V1/ServiceCategoryController.php
    app/Http/Controllers/Api/V1/ServiceController.php
    app/Http/Controllers/Api/V1/ZoneController.php
    app/Http/Controllers/Api/V1/ProviderController.php
    app/Http/Controllers/Api/V1/ProviderProfileController.php
    app/Http/Controllers/Api/V1/Admin/ReferenceController.php
    app/Http/Controllers/Api/V1/Admin/DashboardController.php
    routes/api_titilola.php
    tests/Feature/Api/TitilolaReferenceApiTest.php
)

for f in "${PHP_FILES[@]}"; do
    php -l "$f" >/dev/null
done
ok "Syntaxe PHP valide."

info "Routes API détectées :"
php artisan route:list --path=api || warn "Impossible d'afficher les routes API."

if grep -q "admin" routes/api_titilola.php && ! grep -q "admin.*EnsureAdmin\|EnsureAdmin.*admin\|'admin'" bootstrap/app.php; then
    warn "Vérifiez que l'alias middleware 'admin' est bien enregistré dans bootstrap/app.php."
fi

if [[ "${SKIP_TESTS:-0}" != "1" ]]; then
    info "Build frontend..."
    npm run build || warn "Le build frontend a échoué. Corrigez avant le merge."

    info "Tests ciblés Titilola..."
    php artisan test --filter=TitilolaReferenceApiTest || warn \
        "Les tests Titilola ont échoué. Vérifiez la base de test et les champs fillable des modèles."
else
    warn "Tests ignorés (SKIP_TESTS=1)."
fi

# -----------------------------------------------------------------------------
# 14. RAPPORT FINAL
# -----------------------------------------------------------------------------
printf "\n============================================================\n"
printf " Service229 — Pôle Titilola : automatisation terminée\n"
printf "============================================================\n\n"

printf "Créé/configuré :\n"
printf "  ✓ Sanctum / socle API (si absent)\n"
printf "  ✓ routes/api_titilola.php\n"
printf "  ✓ API /api/v1 catégories, services, zones\n"
printf "  ✓ API publique prestataires\n"
printf "  ✓ sync services/zones du prestataire connecté\n"
printf "  ✓ CRUD API Admin du référentiel\n"
printf "  ✓ Dashboard API Admin\n"
printf "  ✓ Resources JSON\n"
printf "  ✓ Trait de réponse JSON commune\n"
printf "  ✓ Tests Feature de base\n"
printf "  ✓ docs/TITILOLA_API_CONTRACT.md\n\n"

printf "À valider manuellement AVANT merge :\n"
printf "  1. champ exact de validation administrative ProviderProfile ;\n"
printf "  2. champs obligatoires éventuels de provider_profiles ;\n"
printf "  3. alias middleware admin dans bootstrap/app.php ;\n"
printf "  4. contrat Reports / Disputes avec Abed ;\n"
printf "  5. scénario E2E « Carrelage + Tankpè ».\n\n"

printf "Commandes recommandées ensuite :\n"
printf "  git status\n"
printf "  git diff --stat\n"
printf "  php artisan route:list --path=api\n"
printf "  php artisan test --filter=TitilolaReferenceApiTest\n"
printf "  npm run build\n\n"

printf "Commit suggéré :\n"
printf "  git add .\n"
printf "  git commit -m \"feat: add Titilola platform API v1\"\n\n"

ok "Terminé sans opération destructive sur la base de données."
