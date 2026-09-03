<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Report;
use Illuminate\View\View;

class ReportController extends Controller
{
    public function index(): View
    {
        return view('admin.reports.index', [
            'reports' => Report::query()
                ->with(['reporter', 'mission'])
                ->latest()
                ->paginate(20),
        ]);
    }

    public function show(Report $report): View
    {
        $report->load(['reporter', 'mission']);

        return view('admin.reports.show', compact('report'));
    }
}
