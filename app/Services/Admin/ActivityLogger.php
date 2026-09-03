<?php

namespace App\Services\Admin;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ActivityLogger
{
    public function log(?int $userId, string $action): void
    {
        if (!Schema::hasTable('activity_logs')) {
            return;
        }

        DB::table('activity_logs')->insert([
            'user_id' => $userId,
            'action' => $action,
            'created_at' => now(),
        ]);
    }
}
