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
