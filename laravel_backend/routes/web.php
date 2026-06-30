<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\UsersController;
use App\Http\Controllers\Admin\AnalyticsController;
use App\Http\Controllers\Admin\StudiosController;
use App\Http\Controllers\Admin\CouponsController;
use App\Http\Controllers\Admin\SubscriptionsController;
use App\Http\Controllers\Admin\BroadcastsController;
use App\Http\Controllers\Admin\FilesController;
use App\Http\Controllers\Admin\SupportController;
use App\Http\Controllers\Admin\SecurityController;
use App\Http\Controllers\Admin\AuditController;
use App\Http\Controllers\Admin\SettingsController;

Route::get('/', function () {
    return view('landing');
})->name('landing');

/*
|--------------------------------------------------------------------------
| Admin Console (Laravel Blade — replaces the Next.js admin panel)
|--------------------------------------------------------------------------
| Session-based auth via the web guard. Only ADMIN-role users may enter.
| Phase 0 ships Dashboard; remaining modules are stubbed so the sidebar
| never 404s and each can be filled in one at a time.
*/
Route::prefix('admin')->name('admin.')->group(function () {

    // Guest (login)
    Route::get('login', [AdminAuthController::class, 'showLogin'])->name('login');
    Route::post('login', [AdminAuthController::class, 'login'])->name('login.submit');

    // Authenticated + ADMIN role
    Route::middleware(['auth', 'admin.web'])->group(function () {
        Route::post('logout', [AdminAuthController::class, 'logout'])->name('logout');

        Route::get('/', [DashboardController::class, 'index'])->name('dashboard');

        // --- Users module (Phase 1 — ported from Next.js) ---
        Route::get('users', [UsersController::class, 'index'])->name('users');
        Route::get('users/export', [UsersController::class, 'exportCsv'])->name('users.export');
        Route::post('users', [UsersController::class, 'store'])->name('users.store');
        Route::get('users/{id}', [UsersController::class, 'show'])->name('users.show');
        Route::patch('users/{id}/role', [UsersController::class, 'setRole'])->name('users.role');
        Route::patch('users/{id}/plan', [UsersController::class, 'setPlan'])->name('users.plan');
        Route::patch('users/{id}/suspend', [UsersController::class, 'suspend'])->name('users.suspend');

        // --- Bookings / Payments / Finance ---
        // REMOVED by request: the admin console must NOT expose any user's
        // bookings, payments, income, or expenses. These routes (and their
        // sidebar links, dashboard cards, and API endpoints) are intentionally
        // disabled so studio finance/booking data stays private to the owner.

        // --- Analytics ---
        Route::get('analytics', [AnalyticsController::class, 'index'])->name('analytics');

        // --- Studios (Businesses) ---
        Route::get('studios', [StudiosController::class, 'index'])->name('studios');

        // --- Subscriptions & Features ---
        Route::get('subscriptions', [SubscriptionsController::class, 'index'])->name('subscriptions');
        Route::patch('subscriptions/{key}/toggle', [SubscriptionsController::class, 'toggle'])->name('subscriptions.toggle');

        // --- Coupons (CRUD) ---
        Route::get('coupons', [CouponsController::class, 'index'])->name('coupons');
        Route::post('coupons', [CouponsController::class, 'store'])->name('coupons.store');
        Route::patch('coupons/{id}/toggle', [CouponsController::class, 'toggle'])->name('coupons.toggle');
        Route::delete('coupons/{id}', [CouponsController::class, 'destroy'])->name('coupons.destroy');

        // --- Broadcasts / Notifications ---
        Route::get('broadcasts', [BroadcastsController::class, 'index'])->name('broadcasts');
        Route::post('broadcasts', [BroadcastsController::class, 'store'])->name('broadcasts.store');
        Route::patch('broadcasts/{id}/toggle', [BroadcastsController::class, 'toggle'])->name('broadcasts.toggle');
        Route::delete('broadcasts/{id}', [BroadcastsController::class, 'destroy'])->name('broadcasts.destroy');

        // --- Files ---
        Route::get('files', [FilesController::class, 'index'])->name('files');
        Route::delete('files/{name}', [FilesController::class, 'destroy'])->name('files.destroy');

        // --- Support & FAQ ---
        Route::get('support', [SupportController::class, 'index'])->name('support');
        Route::patch('support/{id}/reply', [SupportController::class, 'reply'])->name('support.reply');
        Route::post('support/faq', [SupportController::class, 'storeFaq'])->name('support.faq.store');
        Route::delete('support/faq/{id}', [SupportController::class, 'destroyFaq'])->name('support.faq.destroy');

        // --- Security ---
        Route::get('security', [SecurityController::class, 'index'])->name('security');
        Route::post('security/block', [SecurityController::class, 'blockIp'])->name('security.block');
        Route::delete('security/unblock/{ip}', [SecurityController::class, 'unblockIp'])->name('security.unblock')->where('ip', '.*');

        // --- Audit Log ---
        Route::get('audit', [AuditController::class, 'index'])->name('audit');

        // --- Settings ---
        Route::get('settings', [SettingsController::class, 'index'])->name('settings');
        Route::put('settings', [SettingsController::class, 'update'])->name('settings.update');
    });
});
