<?php

namespace App\Services\Admin;

use Illuminate\Support\Facades\DB;
use Throwable;

class SystemHealthService
{
    public function get(): array
    {
        $startedAt = microtime(true);

        $database = $this->databaseStatus();
        $disk = $this->diskStatus();
        $log = $this->logStatus();

        return [
            'application' => [
                'ok' => true,
                'label' => 'Opérationnelle',
            ],
            'database' => $database,
            'response_ms' => round((microtime(true) - $startedAt) * 1000, 2),
            'memory_mb' => round(memory_get_usage(true) / 1024 / 1024, 2),
            'cpu_load' => $this->cpuLoad(),
            'disk' => $disk,
            'docker' => [
                'detected' => file_exists('/.dockerenv'),
                'label' => file_exists('/.dockerenv') ? 'Environnement conteneurisé détecté' : 'Non détecté depuis PHP',
            ],
            'log' => $log,
        ];
    }

    private function databaseStatus(): array
    {
        try {
            DB::select('SELECT 1');
            return ['ok' => true, 'label' => 'Connectée'];
        } catch (Throwable $e) {
            return ['ok' => false, 'label' => 'Indisponible'];
        }
    }

    private function cpuLoad(): ?float
    {
        if (!function_exists('sys_getloadavg')) {
            return null;
        }

        $load = sys_getloadavg();
        return isset($load[0]) ? round((float) $load[0], 2) : null;
    }

    private function diskStatus(): array
    {
        $path = storage_path();
        $total = @disk_total_space($path);
        $free = @disk_free_space($path);

        if (!$total || $free === false) {
            return ['percent' => null, 'free_gb' => null, 'total_gb' => null];
        }

        $used = $total - $free;

        return [
            'percent' => round(($used / $total) * 100, 1),
            'free_gb' => round($free / 1024 / 1024 / 1024, 2),
            'total_gb' => round($total / 1024 / 1024 / 1024, 2),
        ];
    }

    private function logStatus(): array
    {
        $file = storage_path('logs/laravel.log');

        if (!is_file($file)) {
            return ['exists' => false, 'errors' => 0, 'lines' => []];
        }

        $lines = @file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [];
        $tail = array_slice($lines, -30);
        $errors = count(array_filter($tail, fn ($line) => str_contains($line, '.ERROR')));

        return [
            'exists' => true,
            'errors' => $errors,
            'lines' => array_slice($tail, -10),
        ];
    }
}
