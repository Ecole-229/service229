<?php

namespace App\Services\Admin;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardMetricsService
{
    public function get(): array
    {
        return [
            'users' => $this->count('users'),
            'providers' => $this->count('provider_profiles'),
            'active_requests' => $this->countWhereIn('service_requests', 'status', ['published', 'matched', 'assigned']),
            'missions_in_progress' => $this->countWhere('missions', 'status', 'in_progress'),
            'missions_completed' => $this->countWhere('missions', 'status', 'completed'),
            'reports' => $this->count('reports'),
            'recent_activity' => $this->recentActivity(),
            'top_services' => $this->topServices(),
            'top_zones' => $this->topZones(),
        ];
    }

    private function count(string $table): int
    {
        return Schema::hasTable($table) ? DB::table($table)->count() : 0;
    }

    private function countWhere(string $table, string $column, string $value): int
    {
        return Schema::hasTable($table) && Schema::hasColumn($table, $column)
            ? DB::table($table)->where($column, $value)->count()
            : 0;
    }

    private function countWhereIn(string $table, string $column, array $values): int
    {
        return Schema::hasTable($table) && Schema::hasColumn($table, $column)
            ? DB::table($table)->whereIn($column, $values)->count()
            : 0;
    }

    private function recentActivity(): array
    {
        if (!Schema::hasTable('activity_logs')) {
            return [];
        }

        return DB::table('activity_logs')
            ->latest('created_at')
            ->limit(8)
            ->get()
            ->map(fn ($row) => (array) $row)
            ->all();
    }

    private function topServices(): array
    {
        if (!Schema::hasTable('service_requests') || !Schema::hasTable('services')) {
            return [];
        }

        return DB::table('service_requests')
            ->join('services', 'services.id', '=', 'service_requests.service_id')
            ->select('services.name', DB::raw('COUNT(service_requests.id) as total'))
            ->groupBy('services.id', 'services.name')
            ->orderByDesc('total')
            ->limit(5)
            ->get()
            ->map(fn ($row) => ['name' => $row->name, 'total' => (int) $row->total])
            ->all();
    }

    private function topZones(): array
    {
        if (!Schema::hasTable('service_requests') || !Schema::hasTable('zones')) {
            return [];
        }

        return DB::table('service_requests')
            ->join('zones', 'zones.id', '=', 'service_requests.zone_id')
            ->select('zones.name', DB::raw('COUNT(service_requests.id) as total'))
            ->groupBy('zones.id', 'zones.name')
            ->orderByDesc('total')
            ->limit(5)
            ->get()
            ->map(fn ($row) => ['name' => $row->name, 'total' => (int) $row->total])
            ->all();
    }
}
