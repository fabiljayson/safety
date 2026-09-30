<?php

use App\Http\Controllers\DashboardController;
use App\Http\Controllers\WebAuthController;
use App\Http\Middleware\EnsureUserIsAuthority;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/lang/{locale}', function (string $locale) {
    if (in_array($locale, ['fr', 'en'])) {
        session()->put('locale', $locale);
    }

    return redirect()->back();
})->name('lang.switch');

// Admin Routes
Route::prefix('admin')->group(function () {
    Route::get('/login', [WebAuthController::class, 'showLogin'])->name('admin.login');
    Route::post('/login', [WebAuthController::class, 'login'])->middleware('throttle:5,1');
    Route::post('/logout', [WebAuthController::class, 'logout'])->name('admin.logout');

    // The dashboard can list unverified alerts, verify them and trigger a mass
    // broadcast, so session auth alone is not enough: the authority role is
    // enforced on every request rather than only at login time.
    Route::middleware(['auth', EnsureUserIsAuthority::class])->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('admin.dashboard');
        Route::get('/export-pdf', [DashboardController::class, 'exportPdf'])->name('admin.export.pdf');
        Route::post('/children/{child}/verify', [DashboardController::class, 'verifyChild'])->name('admin.children.verify');
        Route::post('/children/{child}/found', [DashboardController::class, 'markAsFound'])->name('admin.children.found');
    });
});
