<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Social sign-in (Google / Apple). Both endpoints verify the provider's
 * ID token SERVER-SIDE — the client's word is never trusted — then find
 * or create the matching user and issue a normal Sanctum token, so the
 * rest of the app sees no difference from email/password login.
 *
 * Optional .env hardening:
 *   GOOGLE_CLIENT_IDS=<comma-separated allowed aud values>
 *   APPLE_BUNDLE_ID=com.clickerpro.app
 */
class SocialAuthController extends Controller
{
    // ───────────────────────── Google ─────────────────────────

    public function google(Request $request)
    {
        $data = $request->validate(['idToken' => 'required|string']);

        // Google's tokeninfo endpoint validates signature + expiry for us.
        $resp = Http::timeout(10)->get(
            'https://oauth2.googleapis.com/tokeninfo',
            ['id_token' => $data['idToken']]
        );

        if (!$resp->successful()) {
            return response()->json(['message' => 'Invalid Google token'], 401);
        }

        $claims = $resp->json();

        if (($claims['iss'] ?? '') !== 'https://accounts.google.com'
            && ($claims['iss'] ?? '') !== 'accounts.google.com') {
            return response()->json(['message' => 'Invalid Google token'], 401);
        }
        if (($claims['email_verified'] ?? 'false') !== 'true') {
            return response()->json(['message' => 'Google email not verified'], 401);
        }

        // Pin the audience when configured (recommended in production).
        $allowed = array_filter(array_map('trim', explode(',', env('GOOGLE_CLIENT_IDS', ''))));
        if ($allowed && !in_array($claims['aud'] ?? '', $allowed, true)) {
            Log::warning('Google login rejected: unexpected aud ' . ($claims['aud'] ?? 'none'));
            return response()->json(['message' => 'Invalid Google token'], 401);
        }

        return $this->issueFor(
            email: $claims['email'],
            name: $claims['name'] ?? Str::before($claims['email'], '@'),
            avatar: $claims['picture'] ?? null,
        );
    }

    // ───────────────────────── Apple ─────────────────────────

    public function apple(Request $request)
    {
        $data = $request->validate([
            'identityToken' => 'required|string',
            'name' => 'nullable|string|max:255',
        ]);

        $claims = $this->verifyAppleToken($data['identityToken']);
        if ($claims === null) {
            return response()->json(['message' => 'Invalid Apple token'], 401);
        }

        $email = $claims['email'] ?? null;
        if (!$email) {
            // Apple only includes the email on the FIRST authorization.
            return response()->json([
                'message' => 'Apple did not share an email. Remove this app from '
                    . 'Settings → Apple ID → Sign-In & Security → Sign in with Apple, then try again.',
            ], 422);
        }

        return $this->issueFor(
            email: $email,
            name: $data['name'] ?? Str::before($email, '@'),
            avatar: null,
        );
    }

    /** Full JWS verification against Apple's published JWKS. */
    private function verifyAppleToken(string $jwt): ?array
    {
        $parts = explode('.', $jwt);
        if (count($parts) !== 3) {
            return null;
        }
        [$h, $p, $s] = $parts;
        $header = json_decode($this->b64d($h), true);
        $claims = json_decode($this->b64d($p), true);
        $sig = $this->b64d($s);
        if (!$header || !$claims || !$sig) {
            return null;
        }

        $keys = Cache::remember('apple.jwks', 3600, function () {
            $r = Http::timeout(10)->get('https://appleid.apple.com/auth/keys');
            return $r->successful() ? ($r->json('keys') ?? []) : [];
        });

        $jwk = collect($keys)->firstWhere('kid', $header['kid'] ?? '');
        if (!$jwk) {
            return null;
        }

        $pem = $this->rsaJwkToPem($jwk['n'], $jwk['e']);
        $ok = openssl_verify("$h.$p", $sig, $pem, OPENSSL_ALGO_SHA256);
        if ($ok !== 1) {
            return null;
        }

        if (($claims['iss'] ?? '') !== 'https://appleid.apple.com') {
            return null;
        }
        if (($claims['exp'] ?? 0) < time()) {
            return null;
        }
        $bundle = env('APPLE_BUNDLE_ID', 'com.clickerpro.app');
        if (($claims['aud'] ?? '') !== $bundle) {
            return null;
        }

        return $claims;
    }

    /** Builds an RSA public key PEM from a JWK's n/e (base64url) values. */
    private function rsaJwkToPem(string $n, string $e): string
    {
        $mod = $this->derInt($this->b64d($n));
        $exp = $this->derInt($this->b64d($e));
        $rsa = $this->derSeq($mod . $exp);
        $algo = $this->derSeq(
            "\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x01" . "\x05\x00"
        );
        $bitstr = "\x03" . $this->derLen(strlen($rsa) + 1) . "\x00" . $rsa;
        $spki = $this->derSeq($algo . $bitstr);

        return "-----BEGIN PUBLIC KEY-----\n"
            . chunk_split(base64_encode($spki), 64, "\n")
            . "-----END PUBLIC KEY-----\n";
    }

    private function derLen(int $len): string
    {
        if ($len < 0x80) {
            return chr($len);
        }
        $bytes = ltrim(pack('N', $len), "\x00");
        return chr(0x80 | strlen($bytes)) . $bytes;
    }

    private function derInt(string $raw): string
    {
        if (ord($raw[0]) > 0x7f) {
            $raw = "\x00" . $raw;
        }
        return "\x02" . $this->derLen(strlen($raw)) . $raw;
    }

    private function derSeq(string $body): string
    {
        return "\x30" . $this->derLen(strlen($body)) . $body;
    }

    private function b64d(string $b64url): string|false
    {
        return base64_decode(strtr($b64url, '-_', '+/'));
    }

    // ───────────────────────── shared ─────────────────────────

    private function issueFor(string $email, string $name, ?string $avatar)
    {
        $user = User::where('email', $email)->first();

        if ($user && !$user->is_active) {
            return response()->json(['message' => 'Account is disabled'], 403);
        }

        if (!$user) {
            $user = new User([
                'name' => $name,
                'email' => $email,
                // Social accounts get an unguessable password — they can
                // set a real one later via Forgot Password.
                'password' => Str::random(40),
                'public_booking_token' => Str::uuid(),
            ]);
            if ($avatar) {
                $user->avatar = $avatar;
            }
            $user->forceFill([
                'role' => 'OWNER',
                'plan' => 'FREE',
                'is_active' => true,
            ])->save();
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'data' => ['token' => $token, 'user' => new UserResource($user)],
        ]);
    }
}
