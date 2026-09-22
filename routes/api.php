<?php

use Illuminate\Support\Facades\Route;

Route::get('/health', fn () => response()->json([
    'success' => true,
    'message' => 'API Service229 opérationnelle.',
]));

require __DIR__.'/api_titilola.php';
