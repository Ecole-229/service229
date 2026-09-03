<?php

use App\Http\Controllers\Admin\ActivityLogController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\MonitoringController;
use App\Http\Controllers\Admin\ReportController;
use App\Http\Controllers\Admin\ServiceCategoryController;
use App\Http\Controllers\Admin\ServiceController;
use App\Http\Controllers\Admin\ServiceRequestSupervisionController;
use App\Http\Controllers\Admin\StatisticsController;
use App\Http\Controllers\Admin\UserSupervisionController;
use Illuminate\Support\Facades\Route;

Route::middleware(['auth', 'admin'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {
        Route::get('/', DashboardController::class)->name('dashboard');

        Route::resource('categories', ServiceCategoryController::class)
            ->except(['show', 'destroy']);
        Route::resource('services', ServiceController::class)
            ->except(['show', 'destroy']);

        Route::get('users', [UserSupervisionController::class, 'index'])->name('users.index');
        Route::get('users/{user}', [UserSupervisionController::class, 'show'])->name('users.show');

        Route::get('requests', [ServiceRequestSupervisionController::class, 'index'])->name('requests.index');
        Route::get('requests/{requestId}', [ServiceRequestSupervisionController::class, 'show'])->name('requests.show');

        Route::get('reports', [ReportController::class, 'index'])->name('reports.index');
        Route::get('reports/{report}', [ReportController::class, 'show'])->name('reports.show');

        Route::get('statistics', StatisticsController::class)->name('statistics.index');
        Route::get('logs', ActivityLogController::class)->name('logs.index');
        Route::get('monitoring', MonitoringController::class)->name('monitoring.index');
    });
