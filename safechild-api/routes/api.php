<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\MissingChildController;
use App\Http\Controllers\ReportController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [\App\Http\Controllers\PasswordResetController::class, 'sendResetToken']);
Route::post('/reset-password', [\App\Http\Controllers\PasswordResetController::class, 'resetPassword']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/update-location', [AuthController::class, 'updateLocation']);
    Route::post('/update-fcm-token', [AuthController::class, 'updateFcmToken']);

    // Missing Children
    Route::get('/missing-children', [MissingChildController::class, 'index']);
    Route::post('/missing-children', [MissingChildController::class, 'store']);
    Route::get('/missing-children/{missing_child}', [MissingChildController::class, 'show']);
    Route::put('/missing-children/{missing_child}', [MissingChildController::class, 'update']);
    Route::post('/missing-children/{missing_child}/verify', [MissingChildController::class, 'verify']);

    // Reports
    Route::get('/reports', [ReportController::class, 'index']);
    Route::post('/reports', [ReportController::class, 'store']);

    // Analytics
    Route::get('/danger-zones', [\App\Http\Controllers\AnalyticsController::class, 'dangerZones']);
});
