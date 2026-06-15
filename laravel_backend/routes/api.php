<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\ClientController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\InvoiceController;
use App\Http\Controllers\Api\AssignmentController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\GearController;
use App\Http\Controllers\Api\RentController;
use App\Http\Controllers\Api\TeamController;
use App\Http\Controllers\Api\BroadcastController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SearchController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\SupportController;
use App\Http\Controllers\Api\FaqController;
use App\Http\Controllers\Api\ReEditController;
use App\Http\Controllers\Api\TaskController;
use App\Http\Controllers\Api\PackageController;
use App\Http\Controllers\Api\WaitlistController;
use App\Http\Controllers\Api\ReminderController;
use App\Http\Controllers\Api\DeviceTokenController;
use App\Http\Controllers\Api\EntitlementController;
use App\Http\Controllers\Api\CouponController;
use App\Http\Controllers\Api\AuditLogController;
use App\Http\Controllers\Api\SecurityController;
use App\Http\Controllers\Api\SettingsController;
use App\Http\Controllers\Api\FeatureFlagController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\LegalController;
use App\Http\Controllers\Api\AccountController;
use App\Http\Controllers\Api\FileController;
use App\Http\Controllers\Api\DeliveryController;
use App\Http\Controllers\Api\ExtraTimeController;
use App\Http\Controllers\Api\PublicBookingController;
use App\Http\Controllers\Api\PettyCashController;
use App\Http\Controllers\Api\FollowupController;
use App\Http\Controllers\Api\FreelancerController;

// Public auth routes. Each flow gets its OWN throttle bucket so a burst
// of OTP requests can no longer lock a legitimate user out of login
// (previously all seven routes shared one 6/min bucket per IP).
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register'])->middleware('throttle:5,10');
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('forgot', [AuthController::class, 'forgotPassword'])->middleware('throttle:4,1');
    Route::post('reset', [AuthController::class, 'resetPassword'])->middleware('throttle:6,1');
    Route::post('otp/request', [AuthController::class, 'requestOtp'])->middleware('throttle:4,1');
    Route::post('otp/verify', [AuthController::class, 'verifyOtp'])->middleware('throttle:8,1');
    Route::post('accept-invite', [AuthController::class, 'acceptInvite'])->middleware('throttle:6,1');
    Route::post('google', [\App\Http\Controllers\Api\SocialAuthController::class, 'google'])->middleware('throttle:10,1');
    Route::post('apple', [\App\Http\Controllers\Api\SocialAuthController::class, 'apple'])->middleware('throttle:10,1');
});

// Other public endpoints — moderate throttle.
Route::middleware('throttle:30,1')->group(function () {
    Route::get('legal/privacy/{lang}', [LegalController::class, 'privacy']);
    Route::get('legal/terms/{lang}', [LegalController::class, 'terms']);
    Route::get('public-booking/{token}', [PublicBookingController::class, 'show']);
    Route::post('public-booking/{token}', [PublicBookingController::class, 'store']);
    Route::post('contact', [\App\Http\Controllers\Api\ContactController::class, 'store']);
    Route::post('crash-reports', [\App\Http\Controllers\Api\CrashReportController::class, 'store']);
    // Over-the-air update channel: the mobile app polls this on launch.
    Route::get('app/version', [\App\Http\Controllers\Api\AppVersionController::class, 'show']);
});

// Protected routes — authenticated + general per-user throttle.
Route::middleware(['auth:sanctum', 'throttle:120,1'])->group(function () {
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::post('auth/change-password', [AuthController::class, 'changePassword']);

    Route::get('profile', [ProfileController::class, 'show']);
    Route::patch('profile', [ProfileController::class, 'update']);
    Route::post('profile/role', [ProfileController::class, 'changeRole']);

    // Bookings
    Route::get('bookings', [BookingController::class, 'index']);
    Route::post('bookings', [BookingController::class, 'store']);
    Route::get('bookings/{id}', [BookingController::class, 'show']);
    Route::patch('bookings/{id}', [BookingController::class, 'update']);
    Route::patch('bookings/{id}/status', [BookingController::class, 'updateStatus']);
    Route::delete('bookings/{id}', [BookingController::class, 'destroy']);

    // Assignments
    Route::get('bookings/{eventId}/assignments', [AssignmentController::class, 'index']);
    Route::post('bookings/{eventId}/assignments', [AssignmentController::class, 'store']);
    Route::patch('bookings/{eventId}/assignments/{id}', [AssignmentController::class, 'update']);
    Route::delete('bookings/{eventId}/assignments/{id}', [AssignmentController::class, 'destroy']);

    // Clients
    Route::get('clients', [ClientController::class, 'index']);
    Route::post('clients', [ClientController::class, 'store']);
    Route::get('clients/{id}', [ClientController::class, 'show']);
    Route::patch('clients/{id}', [ClientController::class, 'update']);
    Route::delete('clients/{id}', [ClientController::class, 'destroy']);

    // Payments
    Route::get('payments', [PaymentController::class, 'index']);
    Route::post('payments', [PaymentController::class, 'store']);
    Route::get('payments/event/{eventId}', [PaymentController::class, 'byEvent']);
    Route::get('payments/earnings', [PaymentController::class, 'earnings']);
    Route::patch('payments/{id}', [PaymentController::class, 'update']);
    Route::delete('payments/{id}', [PaymentController::class, 'destroy']);

    // Invoices
    Route::get('invoices', [InvoiceController::class, 'index']);
    Route::post('invoices', [InvoiceController::class, 'store']);
    Route::get('invoices/{id}', [InvoiceController::class, 'show']);
    Route::get('invoices/event/{eventId}', [InvoiceController::class, 'byEvent']);
    Route::patch('invoices/{id}', [InvoiceController::class, 'update']);

    // Expenses
    Route::get('expenses', [ExpenseController::class, 'index']);
    Route::post('expenses', [ExpenseController::class, 'store']);
    Route::patch('expenses/{id}', [ExpenseController::class, 'update']);
    Route::delete('expenses/{id}', [ExpenseController::class, 'destroy']);

    // Gear
    Route::get('gear', [GearController::class, 'index']);
    Route::post('gear', [GearController::class, 'store']);
    Route::patch('gear/{id}', [GearController::class, 'update']);
    Route::delete('gear/{id}', [GearController::class, 'destroy']);
    Route::get('gear/{gearId}/rent', [RentController::class, 'index']);
    Route::get('rent', [RentController::class, 'all']);
    Route::post('rent', [RentController::class, 'store']);
    Route::patch('rent/{id}', [RentController::class, 'update']);

    // Petty Cash
    Route::get('petty-cash', [PettyCashController::class, 'index']);
    Route::post('petty-cash', [PettyCashController::class, 'store']);
    Route::patch('petty-cash/{id}', [PettyCashController::class, 'update']);
    Route::delete('petty-cash/{id}', [PettyCashController::class, 'destroy']);

    // Follow-ups
    Route::get('followups', [FollowupController::class, 'index']);
    Route::post('followups', [FollowupController::class, 'store']);
    Route::patch('followups/{id}', [FollowupController::class, 'update']);
    Route::delete('followups/{id}', [FollowupController::class, 'destroy']);

    // Freelancer tools
    Route::get('freelancer/blackouts', [FreelancerController::class, 'blackouts']);
    Route::post('freelancer/blackouts', [FreelancerController::class, 'storeBlackout']);
    Route::delete('freelancer/blackouts/{id}', [FreelancerController::class, 'destroyBlackout']);
    Route::get('freelancer/leaves', [FreelancerController::class, 'leaves']);
    Route::post('freelancer/leaves', [FreelancerController::class, 'storeLeave']);
    Route::patch('freelancer/leaves/{id}', [FreelancerController::class, 'updateLeave']);
    Route::delete('freelancer/leaves/{id}', [FreelancerController::class, 'destroyLeave']);
    Route::get('freelancer/work-history', [FreelancerController::class, 'workHistory']);
    Route::get('freelancer/earnings', [FreelancerController::class, 'earnings']);
    Route::post('freelancer/earnings/request-payment', [FreelancerController::class, 'requestPayment'])->middleware('throttle:10,1');
    Route::get('freelancer/dashboard/events', [FreelancerController::class, 'dashboardEvents']);
    Route::get('freelancer/dashboard/conflicts', [FreelancerController::class, 'dashboardConflicts']);
    Route::post('freelancer/checkin', [FreelancerController::class, 'checkin']);
    Route::get('freelancer/checkin/{eventId}', [FreelancerController::class, 'checkinStatus']);

    // Packages
    Route::get('packages', [PackageController::class, 'index']);
    Route::post('packages', [PackageController::class, 'store']);
    Route::patch('packages/{id}', [PackageController::class, 'update']);
    Route::delete('packages/{id}', [PackageController::class, 'destroy']);

    // Team
    Route::get('team', [TeamController::class, 'members']);
    Route::get('team/invite', [TeamController::class, 'getInvite']);
    Route::post('team/invite', [TeamController::class, 'invite']);
    Route::post('team/join', [TeamController::class, 'join'])->middleware('throttle:10,1');
    Route::post('team/invite-email', [TeamController::class, 'inviteByEmail'])->middleware('throttle:10,1');
    Route::get('team/invites/pending', [TeamController::class, 'pendingInvites']);
    Route::post('team/invites/{id}/respond', [TeamController::class, 'respondInvite']);
    Route::get('team/members', [TeamController::class, 'members']);
    Route::get('team/payouts', [TeamController::class, 'staffPayouts']);
    Route::post('team/members/{userId}/payouts/pay', [TeamController::class, 'markPayoutPaid']);
    Route::get('team/members/{userId}/profile', [TeamController::class, 'memberProfile']);
    Route::patch('team/members/{userId}/permissions', [TeamController::class, 'updatePermissions']);
    Route::delete('team/members/{userId}', [TeamController::class, 'removeMember']);

    // Re-edits
    Route::get('bookings/{eventId}/reedits', [ReEditController::class, 'index']);
    Route::post('bookings/{eventId}/reedits', [ReEditController::class, 'store']);
    Route::patch('reedits/{id}', [ReEditController::class, 'update']);

    // Tasks
    Route::get('bookings/{eventId}/tasks', [TaskController::class, 'index']);
    Route::post('bookings/{eventId}/tasks', [TaskController::class, 'upsert']);

    // Reports
    Route::get('reports/summary', [ReportController::class, 'summary']);
    Route::get('reports/yearly-summary', [ReportController::class, 'yearlySummary']);
    Route::get('reports/team-performance', [ReportController::class, 'teamPerformance']);

    // Search
    Route::get('search', [SearchController::class, 'search']);

    // Notifications & Broadcasts
    Route::get('notifications', [NotificationController::class, 'index']);
    Route::patch('notifications/{id}/read', [NotificationController::class, 'markRead']);
    // Owner→team announcements
    Route::get('announcements', [\App\Http\Controllers\Api\AnnouncementController::class, 'index']);
    Route::post('announcements', [\App\Http\Controllers\Api\AnnouncementController::class, 'store']);
    Route::patch('announcements/{id}', [\App\Http\Controllers\Api\AnnouncementController::class, 'update']);
    Route::delete('announcements/{id}', [\App\Http\Controllers\Api\AnnouncementController::class, 'destroy']);
    Route::post('announcements/{id}/read', [\App\Http\Controllers\Api\AnnouncementController::class, 'markRead']);

    Route::get('broadcasts', [BroadcastController::class, 'index']);
    Route::post('broadcasts/{id}/view', [BroadcastController::class, 'trackView']);
    Route::post('broadcasts/{id}/click', [BroadcastController::class, 'trackClick']);

    // Chat
    Route::get('chat/groups', [ChatController::class, 'groups']);
    Route::post('chat/groups', [ChatController::class, 'createGroup']);
    Route::get('chat/groups/{groupId}/messages', [ChatController::class, 'messages']);
    Route::post('chat/groups/{groupId}/messages', [ChatController::class, 'sendMessage']);
    Route::post('chat/groups/{groupId}/read', [ChatController::class, 'markRead']);

    // Support
    Route::get('support', [SupportController::class, 'index']);
    Route::post('support', [SupportController::class, 'store']);
    Route::get('support/{id}', [SupportController::class, 'show']);
    Route::get('faqs', [FaqController::class, 'index']);

    // Delivery & Extra time
    Route::patch('bookings/{eventId}/delivery', [DeliveryController::class, 'update']);
    Route::post('bookings/{eventId}/extra-time', [ExtraTimeController::class, 'store']);

    // Waitlist
    Route::get('waitlist', [WaitlistController::class, 'index']);
    Route::post('waitlist', [WaitlistController::class, 'store']);
    Route::delete('waitlist/{id}', [WaitlistController::class, 'destroy']);

    // Reminders
    Route::get('reminders', [ReminderController::class, 'index']);
    Route::post('reminders', [ReminderController::class, 'store']);
    Route::delete('reminders/{id}', [ReminderController::class, 'destroy']);

    // My activity log
    Route::get('my-activity', [AuditLogController::class, 'mine']);

    // Two-Factor Auth (user-level — any signed-in user)
    Route::get('security/2fa/status', [SecurityController::class, 'twoFaStatus']);
    Route::post('security/2fa/setup', [SecurityController::class, 'twoFaSetup']);
    Route::post('security/2fa/verify', [SecurityController::class, 'twoFaVerify']);
    Route::post('security/2fa/disable', [SecurityController::class, 'twoFaDisable']);

    // Devices
    Route::post('devices', [DeviceTokenController::class, 'register']);
    Route::delete('devices/{token}', [DeviceTokenController::class, 'unregister']);

    // Entitlements
    Route::get('entitlements/{key}', [EntitlementController::class, 'check']);

    // Coupons (user apply)
    Route::post('coupons/apply', [CouponController::class, 'apply']);

    // Account
    Route::post('account/delete-request', [AccountController::class, 'requestDelete']);
    Route::post('account/cancel-delete', [AccountController::class, 'cancelDelete']);
    Route::post('account/export', [AccountController::class, 'export']);

    // Files
    Route::post('files/upload', [FileController::class, 'upload']);
    Route::delete('files', [FileController::class, 'destroy']);

    // Admin routes
    Route::middleware('admin')->prefix('admin')->group(function () {
        Route::get('stats', [AdminController::class, 'stats']);
        Route::get('analytics', [AdminController::class, 'analytics']);
        Route::get('users', [AdminController::class, 'users']);
        Route::get('users/{id}', [AdminController::class, 'userDetail']);
        Route::patch('users/{id}', [AdminController::class, 'updateUser']);
        Route::patch('users/{id}/role', [AdminController::class, 'setRole']);
        Route::patch('users/{id}/plan', [AdminController::class, 'setPlan']);
        Route::patch('users/{id}/suspend', [AdminController::class, 'setSuspend']);
        Route::get('export', [AdminController::class, 'exportCsv']);
        // Frontend uses /export/<type>.csv — map to the same handler.
        Route::get('export/{file}', [AdminController::class, 'exportCsv']);
        // OTA app-version control (set latest version + APK url).
        Route::patch('app/version', [\App\Http\Controllers\Api\AppVersionController::class, 'update']);

        // All-studio bookings & payments
        Route::get('bookings', [AdminController::class, 'bookings']);
        Route::get('payments', [AdminController::class, 'payments']);

        // Files
        Route::get('files', [FileController::class, 'adminIndex']);
        Route::delete('files/{name}', [FileController::class, 'adminDestroy']);

        Route::get('broadcasts', [BroadcastController::class, 'adminIndex']);
        Route::post('broadcasts', [BroadcastController::class, 'adminStore']);
        Route::patch('broadcasts/{id}', [BroadcastController::class, 'adminUpdate']);
        Route::delete('broadcasts/{id}', [BroadcastController::class, 'adminDestroy']);

        Route::get('support', [SupportController::class, 'adminIndex']);
        Route::patch('support/{id}/reply', [SupportController::class, 'adminReply']);
        // Frontend calls /tickets — alias to support
        Route::get('tickets', [SupportController::class, 'adminIndex']);
        Route::patch('tickets/{id}', [SupportController::class, 'adminReply']);

        Route::get('faqs', [FaqController::class, 'adminIndex']);
        Route::post('faqs', [FaqController::class, 'adminStore']);
        Route::patch('faqs/{id}', [FaqController::class, 'adminUpdate']);
        Route::delete('faqs/{id}', [FaqController::class, 'adminDestroy']);

        Route::get('coupons', [CouponController::class, 'index']);
        Route::post('coupons', [CouponController::class, 'store']);
        Route::patch('coupons/{id}', [CouponController::class, 'update']);
        Route::delete('coupons/{id}', [CouponController::class, 'destroy']);

        Route::get('audit-logs', [AuditLogController::class, 'index']);
        Route::get('audit', [AuditLogController::class, 'index']); // frontend alias

        Route::get('security/login-activity', [SecurityController::class, 'loginActivity']);
        Route::get('security/blocked-ips', [SecurityController::class, 'blockedIps']);
        Route::post('security/block-ip', [SecurityController::class, 'blockIp']);
        Route::delete('security/block-ip/{ip}', [SecurityController::class, 'unblockIp']);
        // Frontend also uses these exact paths:
        Route::post('security/blocked-ips', [SecurityController::class, 'blockIp']);
        Route::delete('security/blocked-ips/{ip}', [SecurityController::class, 'unblockIp']);

        // Two-Factor Auth
        Route::get('security/2fa/status', [SecurityController::class, 'twoFaStatus']);
        Route::post('security/2fa/setup', [SecurityController::class, 'twoFaSetup']);
        Route::post('security/2fa/verify', [SecurityController::class, 'twoFaVerify']);
        Route::post('security/2fa/disable', [SecurityController::class, 'twoFaDisable']);

        Route::get('settings', [SettingsController::class, 'index']);
        Route::post('settings', [SettingsController::class, 'update']);

        Route::get('feature-flags', [FeatureFlagController::class, 'index']);
        Route::patch('feature-flags/{id}', [FeatureFlagController::class, 'update']);
        // Frontend subscription page uses /features and /features/{key}
        Route::get('features', [FeatureFlagController::class, 'index']);
        Route::patch('features/{key}', [FeatureFlagController::class, 'update']);
    });
});
