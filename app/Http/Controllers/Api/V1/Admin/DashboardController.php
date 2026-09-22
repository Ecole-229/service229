<?php

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
