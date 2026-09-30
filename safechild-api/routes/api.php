<?php

use App\Http\Controllers\AnalyticsController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\MissingChildController;
use App\Http\Controllers\PasswordResetController;
use App\Http\Controllers\ReportController;
use Illuminate\Support\Facades\Route;

// Public routes. Every one of these is rate limited: login and the 6-digit
// password-reset OTP are otherwise brute-forceable, and the OTP only has
// 1e6 possible values.
Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:6,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:6,1');
Route::post('/forgot-password', [PasswordResetController::class, 'sendResetToken'])->middleware('throttle:3,1');
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword'])->middleware('throttle:5,1');

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
    Route::get('/danger-zones', [AnalyticsController::class, 'dangerZones']);
});
