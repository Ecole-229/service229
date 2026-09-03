<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class ServiceRequestSupervisionController extends Controller
{
    private const ALLOWED_STATUSES = [
        'draft', 'published', 'matched', 'assigned', 'cancelled', 'expired', 'closed',
    ];

    public function index(Request $request): View
    {
        $query = DB::table('service_requests')
            ->leftJoin('users', 'users.id', '=', 'service_requests.client_id')
            ->leftJoin('services', 'services.id', '=', 'service_requests.service_id')
            ->leftJoin('zones', 'zones.id', '=', 'service_requests.zone_id')
            ->select([
                'service_requests.*',
                'users.name as client_name',
                'services.name as service_name',
                'zones.name as zone_name',
            ])
            ->orderByDesc('service_requests.created_at');

        if ($request->filled('status') && in_array($request->status, self::ALLOWED_STATUSES, true)) {
            $query->where('service_requests.status', $request->status);
        }

        return view('admin.requests.index', [
            'requests' => $query->paginate(20)->withQueryString(),
            'statuses' => self::ALLOWED_STATUSES,
        ]);
    }

    public function show(int $requestId): View
    {
        $serviceRequest = DB::table('service_requests')
            ->leftJoin('users', 'users.id', '=', 'service_requests.client_id')
            ->leftJoin('services', 'services.id', '=', 'service_requests.service_id')
            ->leftJoin('zones', 'zones.id', '=', 'service_requests.zone_id')
            ->select([
                'service_requests.*',
                'users.name as client_name',
                'users.email as client_email',
                'services.name as service_name',
                'zones.name as zone_name',
            ])
            ->where('service_requests.id', $requestId)
            ->first();

        abort_unless($serviceRequest, 404);

        $proposals = DB::table('proposals')
            ->where('request_id', $requestId)
            ->orderByDesc('created_at')
            ->get();

        $mission = DB::table('missions')
            ->where('request_id', $requestId)
            ->first();

        return view('admin.requests.show', compact('serviceRequest', 'proposals', 'mission'));
    }
}
