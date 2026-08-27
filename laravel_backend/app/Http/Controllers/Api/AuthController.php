<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\LoginActivity;
use App\Models\OtpCode;
use App\Models\TeamInviteCode;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AuthController extends Controller
{

    private function sendSignupOtp(User $user, string $source): void
    {
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        OtpCode::create([
            'user_id' => $user->id,
            'code' => $code,
            'purpose' => 'signup',
            'expires_at' => now()->addMinutes(10),
            'used' => false,
        ]);

        Log::info('Signup OTP created.', [
            'email' => $user->email,
            'purpose' => 'signup',
            'source' => $source,
            'mailer' => config('mail.default'),
        ]);

        try {
            Log::info('Signup OTP mail send attempt.', [
                'email' => $user->email,
                'purpose' => 'signup',
                'source' => $source,
            ]);
            Mail::send('emails.auth-code', [
                'subjectLine' => 'Your Graphy7 verification code',
                'preheader' => 'Use this secure code to verify your Graphy7 account.',
                'headline' => 'Verify your email',
                'subhead' => 'One more step to secure your studio account.',
                'intro' => 'Enter this verification code in Graphy7 to finish setting up your account.',
                'contextLabel' => 'Verification code',
                'code' => $code,
                'expiresIn' => '10 minutes',
                'securityNote' => "If you did not try to create or verify a Graphy7 account, you can safely ignore this email.",
            ], function ($message) use ($user) {
                $message->to($user->email)->subject('Your Graphy7 verification code');
            });
            Log::info('Signup OTP mail send completed.', [
                'email' => $user->email,
                'purpose' => 'signup',
                'source' => $source,
            ]);
        } catch (\Throwable $e) {
            Log::warning('Signup OTP mail send failed.', [
                'email' => $user->email,
                'purpose' => 'signup',
                'source' => $source,
                'error' => $e->getMessage(),
            ]);
        }
    }

    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            // One account per phone number (Heaven 2026-07-15: "ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â®ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â° ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾
            // ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â®ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â² ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¼ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â° ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â·ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¶ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¡ ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾").
            'phone' => 'nullable|string|max:30|unique:users,phone',
            'password' => 'required|string|min:6',
            // Self-service signup may only pick a self-service role. ADMIN and
            // MANAGER are privileged and must NEVER be assignable from public
            // registration (MANAGER comes via the invite flow). Anything else
            // falls back to OWNER.
            // OFFICE_STAFF removed (Heaven 2026-07-15) ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â Owner carries all
            // office-staff capabilities; staff no longer use the app.
            'role' => 'nullable|string|in:OWNER,FREELANCER,BOTH',
            // Owner/Both provide the company name at registration so they
            // never have to re-enter it ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â the app was sending this all
            // along but it was silently dropped here.
            'business_name' => 'nullable|string|max:255',
        ]);

        // Privilege fields (role/plan/is_active) are guarded, so set them
        // explicitly with forceFill after building from the safe attributes.
        $user = new User([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'password' => $data['password'],
            'business_name' => $data['business_name'] ?? null,
            'public_booking_token' => Str::uuid(),
        ]);
        // SECURITY / OTP GATE: a freshly registered account is created but NOT
        // logged in. We intentionally do NOT issue an auth token here ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â the
        // account is "unverified" until the email OTP is confirmed. Only
        // verifyOtp() (purpose=signup) issues the token. This closes the hole
        // where registering returned a token immediately, so OTP was optional
        // and reopening the app logged the user in without ever verifying.
        $user->forceFill([
            'role' => $data['role'] ?? 'OWNER',
            'plan' => 'FREE',
            'is_active' => true,
            'email_verified_at' => null, // verified on OTP success
        ])->save();

        $this->sendSignupOtp($user, 'register');

        // No token ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â the client must complete OTP, then receive the token from
        // verifyOtp. The user object is returned only so the app can show the
        // email on the OTP screen.
        return response()->json([
            'data' => [
                'token' => null,
                'requiresOtp' => true,
                'user' => new UserResource($user),
            ],
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        // Include soft-deleted rows: an account inside its 7-day deletion
        // grace window can log back in (which restores it); past the window
        // it is permanently purged (Heaven 2026-07-15).
        $user = User::withTrashed()->where('email', $data['email'])->first();

        if ($user && $user->trashed() && now()->gte($user->deleted_at)) {
            // Grace expired ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â erase the account (FKs cascade) and treat the
            // login as unknown credentials.
            $user->forceDelete();
            $user = null;
        }

        $success = $user && Hash::check($data['password'], $user->password);

        LoginActivity::create([
            'user_id' => $user?->id,
            'email' => $data['email'],
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'success' => $success,
        ]);

        if (!$success) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        if (!$user->is_active) {
            return response()->json(['message' => 'Account is disabled'], 403);
        }

        if ($user->email_verified_at === null) {
            $this->sendSignupOtp($user, 'login');

            return response()->json([
                'message' => 'Email verification required',
                'data' => [
                    'token' => null,
                    'requiresOtp' => true,
                    'purpose' => 'signup',
                    'email' => $user->email,
                    'user' => new UserResource($user),
                ],
            ]);
        }

        // Logging in during the 7-day grace window cancels the pending
        // deletion and restores the account.
        if ($user->trashed()) {
            $user->restore();
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json(['data' => ['token' => $token, 'user' => new UserResource($user)]]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'ok']);
    }

    public function forgotPassword(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $data['email'])->first();
        Log::info('Password reset code requested.', [
            'email' => $data['email'],
            'user_found' => (bool) $user,
            'mailer' => config('mail.default'),
        ]);

        if ($user) {
            // 6-digit numeric code ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â the app shows six OTP-style boxes, so a
            // long random string here reads as a garbage code to the user.
            $token = (string) random_int(100000, 999999);
            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $data['email']],
                ['token' => Hash::make($token), 'created_at' => now()]
            );

            // Email the reset code out-of-band (log mailer in dev). The code
            // is valid for 60 minutes (enforced in resetPassword).
            try {
                Log::info('Password reset mail send attempt.', ['email' => $data['email']]);
                Mail::send('emails.auth-code', [
                    'subjectLine' => 'Your Graphy7 password reset code',
                    'preheader' => 'Use this secure code to reset your Graphy7 password.',
                    'headline' => 'Reset your password',
                    'subhead' => 'Secure access for your studio workspace.',
                    'intro' => 'Use the code below to reset your Graphy7 account password.',
                    'contextLabel' => 'Password reset code',
                    'code' => $token,
                    'expiresIn' => '60 minutes',
                    'securityNote' => "If you did not request a password reset, ignore this email. Your current password will stay unchanged.",
                ], function ($message) use ($data) {
                    $message->to($data['email'])->subject('Your Graphy7 password reset code');
                });
                Log::info('Password reset mail send completed.', ['email' => $data['email']]);
            } catch (\Throwable $e) {
                Log::warning('Reset mail send failed.', [
                    'email' => $data['email'],
                    'error' => $e->getMessage(),
                ]);
            }
        }

        return response()->json(['message' => 'ok']);
    }

    public function resetPassword(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
            'password' => 'required|string|min:8',
        ]);

        $record = DB::table('password_reset_tokens')->where('email', $data['email'])->first();

        if (!$record || !Hash::check($data['token'], $record->token)) {
            return response()->json(['message' => 'Invalid or expired token'], 422);
        }

        // SECURITY: reject tokens older than 60 minutes. Previously a reset
        // token never expired, so a leaked/old token stayed usable forever.
        $createdAt = $record->created_at ? \Illuminate\Support\Carbon::parse($record->created_at) : null;
        if (!$createdAt || $createdAt->lt(now()->subMinutes(60))) {
            DB::table('password_reset_tokens')->where('email', $data['email'])->delete();
            return response()->json(['message' => 'Invalid or expired token'], 422);
        }

        $user = User::where('email', $data['email'])->first();
        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        $user->update(['password' => $data['password']]);
        DB::table('password_reset_tokens')->where('email', $data['email'])->delete();

        return response()->json(['message' => 'ok']);
    }

    public function changePassword(Request $request)
    {
        // Accept both camelCase (web/mobile) and snake_case payloads.
        $current = $request->input('currentPassword', $request->input('current_password'));
        $new = $request->input('newPassword', $request->input('new_password'));

        if (!$current || !$new || strlen($new) < 6) {
            return response()->json(['message' => 'New password must be at least 6 characters'], 422);
        }

        $user = $request->user();

        if (!Hash::check($current, $user->password)) {
            return response()->json(['message' => 'Current password is incorrect'], 422);
        }

        $user->update(['password' => $new]);

        return response()->json(['message' => 'ok']);
    }

    public function requestOtp(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'purpose' => 'required|string',
        ]);

        $user = User::where('email', $data['email'])->first();
        Log::info('OTP requested.', [
            'email' => $data['email'],
            'purpose' => $data['purpose'],
            'user_found' => (bool) $user,
            'mailer' => config('mail.default'),
        ]);
        if (!$user) {
            return response()->json(['message' => 'ok']);
        }

        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        OtpCode::create([
            'user_id' => $user->id,
            'code' => $code,
            'purpose' => $data['purpose'],
            'expires_at' => now()->addMinutes(10),
            'used' => false,
        ]);

        // Deliver the OTP out-of-band via the configured mailer. With
        // MAIL_MAILER=log (dev) it is written to storage/logs/laravel.log;
        // in production set real SMTP creds in .env and the same code emails it.
        // SECURITY: the code is never returned in the HTTP response.
        try {
            Log::info('OTP mail send attempt.', ['email' => $user->email, 'purpose' => $data['purpose']]);
            Mail::send('emails.auth-code', [
                'subjectLine' => 'Your Graphy7 verification code',
                'preheader' => 'Use this secure code to verify your Graphy7 account.',
                'headline' => 'Verify your email',
                'subhead' => 'One more step to secure your studio account.',
                'intro' => 'Enter this verification code in Graphy7 to finish setting up your account.',
                'contextLabel' => 'Verification code',
                'code' => $code,
                'expiresIn' => '10 minutes',
                'securityNote' => "If you did not try to create or verify a Graphy7 account, you can safely ignore this email.",
            ], function ($message) use ($user) {
                $message->to($user->email)->subject('Your Graphy7 verification code');
            });
            Log::info('OTP mail send completed.', ['email' => $user->email, 'purpose' => $data['purpose']]);
        } catch (\Throwable $e) {
            // Never let a mail failure break OTP issuance; log and continue.
            Log::warning('OTP mail send failed.', [
                'email' => $user->email,
                'purpose' => $data['purpose'],
                'error' => $e->getMessage(),
            ]);
        }

        return response()->json(['message' => 'ok']);
    }

    public function verifyOtp(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'code' => 'required|string',
            'purpose' => 'required|string',
        ]);

        $user = User::where('email', $data['email'])->first();
        if (!$user) {
            return response()->json(['message' => 'Invalid OTP'], 422);
        }

        // Find the latest active OTP for this user+purpose (independent of the
        // submitted code) so we can count failed attempts against it and lock
        // it after too many tries ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â preventing brute-force of the 6-digit code.
        $otp = OtpCode::where('user_id', $user->id)
            ->where('purpose', $data['purpose'])
            ->where('used', false)
            ->where('expires_at', '>=', now())
            ->latest()
            ->first();

        if (!$otp) {
            return response()->json(['message' => 'Invalid or expired OTP'], 422);
        }

        // Lock out after 5 failed attempts; the user must request a new code.
        if ($otp->attempts >= 5) {
            $otp->update(['used' => true]); // invalidate so it can't be ground further
            return response()->json(['message' => 'Too many attempts. Request a new OTP.'], 429);
        }

        if (!hash_equals((string) $otp->code, (string) $data['code'])) {
            $otp->increment('attempts');
            return response()->json(['message' => 'Invalid or expired OTP'], 422);
        }

        $otp->update(['used' => true]);

        // For a signup verification, THIS is the moment the account becomes
        // usable: mark the email verified and issue the auth token. Returning
        // the token here (and nowhere earlier) is what makes OTP mandatory ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â
        // without completing this step the user has no session at all.
        if (strtolower((string) $data['purpose']) === 'signup') {
            if ($user->email_verified_at === null) {
                $user->forceFill(['email_verified_at' => now()])->save();
            }
            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'data' => [
                    'token' => $token,
                    'user' => new UserResource($user),
                ],
            ]);
        }

        return response()->json(['message' => 'ok']);
    }

    public function acceptInvite(Request $request)
    {
        // The invitee registers a NEW manager account by redeeming a code.
        // SECURITY: the account is created from the validated signup fields ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â
        // we never trust a client-supplied user_id (which previously let an
        // attacker promote an arbitrary existing account to MANAGER).
        $data = $request->validate([
            'code' => 'required|string',
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
        ]);

        $invite = TeamInviteCode::where('code', $data['code'])
            ->whereNull('used_by')
            ->first();

        if (!$invite) {
            return response()->json(['message' => 'Invalid or already used invite code'], 422);
        }

        if ($invite->expires_at && $invite->expires_at->isPast()) {
            return response()->json(['message' => 'Invite code has expired'], 422);
        }

        $invitee = new User([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'public_booking_token' => Str::uuid(),
        ]);
        // Privilege fields are guarded ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â set explicitly for this trusted flow.
        $invitee->forceFill([
            'role' => 'MANAGER',
            'plan' => 'FREE',
            'is_active' => true,
            'manager_permissions' => ['ownerId' => $invite->owner_id],
        ])->save();

        $invite->update([
            'used_by' => $invitee->id,
            'used_at' => now(),
        ]);

        // Issue a token so the new manager is logged in immediately ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â matches
        // the existing register/login response shape the clients expect.
        $token = $invitee->createToken('auth_token')->plainTextToken;

        return response()->json(['message' => 'ok', 'data' => ['token' => $token, 'user' => new UserResource($invitee)]]);
    }
}
