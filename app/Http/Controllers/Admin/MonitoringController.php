<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\Admin\SystemHealthService;
use Illuminate\View\View;

class MonitoringController extends Controller
{
    public function __invoke(SystemHealthService $healthService): View
    {
        return view('admin.monitoring.index', [
            'health' => $healthService->get(),
        ]);
    }
}
