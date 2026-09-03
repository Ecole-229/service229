<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\Admin\DashboardMetricsService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\View\View;

class StatisticsController extends Controller
{
    public function __invoke(DashboardMetricsService $metricsService): View
    {
        $metrics = $metricsService->get();

        $created = Schema::hasTable('service_requests') ? DB::table('service_requests')->count() : 0;
        $missions = Schema::hasTable('missions') ? DB::table('missions')->count() : 0;

        $transformationRate = $created > 0 ? round(($missions / $created) * 100, 1) : 0;

        return view('admin.statistics.index', [
            'metrics' => $metrics,
            'transformationRate' => $transformationRate,
        ]);
    }
}
