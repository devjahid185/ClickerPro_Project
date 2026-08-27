<?php

namespace App\Services;

use App\Models\DeviceToken;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Sends push notifications through Firebase Cloud Messaging (HTTP v1).
 *
 * Zero composer dependencies by design (shared-hosting friendly): the
 * service-account JSON (FIREBASE_CREDENTIALS path in .env) is used to
 * mint a short-lived OAuth2 access token via an RS256-signed JWT, which
 * is cached for ~50 minutes.
 *
 * Every public method is fail-soft: push delivery must never break the
 * request that triggered it — failures are logged and swallowed.
 */
class PushService
{
    /** True when a credentials file is configured and readable. */
    public function enabled(): bool
    {
        $path = $this->credentialsPath();
        return $path !== null && is_readable($path);
    }

    /**
     * Send a notification to EVERY registered device (e.g. an admin
     * broadcast). Returns the number of tokens attempted.
     */
    public function sendToAll(string $title, string $body, array $data = []): int
    {
        if (!$this->enabled()) {
            return 0;
        }

        $tokens = DeviceToken::pluck('token')->unique()->values();
        foreach ($tokens as $token) {
            $this->sendToToken($token, $title, $body, $data);
        }

        return $tokens->count();
    }

    /** Send a notification to one user's registered devices. */
    public function sendToUser(int $userId, string $title, string $body, array $data = []): int
    {
        if (!$this->enabled()) {
            return 0;
        }

        $tokens = DeviceToken::where('user_id', $userId)
            ->pluck('token')->unique()->values();
        foreach ($tokens as $token) {
            $this->sendToToken($token, $title, $body, $data);
        }

        return $tokens->count();
    }

    /** Send a notification to a selected set of users' registered devices. */
    public function sendToUsers(iterable $userIds, string $title, string $body, array $data = []): int
    {
        if (!$this->enabled()) {
            Log::warning('FCM sendToUsers skipped: credentials not enabled.');
            return 0;
        }

        $ids = collect($userIds)
            ->filter(fn ($id) => $id !== null && $id !== '')
            ->map(fn ($id) => (int) $id)
            ->filter(fn (int $id) => $id > 0)
            ->unique()
            ->values();

        if ($ids->isEmpty()) {
            Log::info('FCM sendToUsers skipped: no target users.');
            return 0;
        }

        $tokens = DeviceToken::whereIn('user_id', $ids)
            ->pluck('token')
            ->unique()
            ->values();
        if ($tokens->isEmpty()) {
            Log::info('FCM sendToUsers skipped: no device tokens.', [
                'user_ids' => $ids->all(),
            ]);
        }
        foreach ($tokens as $token) {
            $this->sendToToken($token, $title, $body, $data);
        }

        return $tokens->count();
    }

    private function sendToToken(string $token, string $title, string $body, array $data): void
    {
        try {
            $accessToken = $this->accessToken();
            $projectId = $this->projectId();
            if (!$accessToken || !$projectId) {
                return;
            }

            $response = Http::withToken($accessToken)
                ->timeout(10)
                ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                    'message' => [
                        'token' => $token,
                        'notification' => ['title' => $title, 'body' => $body],
                        // FCM v1 requires string values in the data map.
                        'data' => array_map('strval', $data),
                        'android' => ['priority' => 'HIGH'],
                    ],
                ]);

            // Dead tokens (uninstalled app) come back 404/UNREGISTERED —
            // prune them so the list stays clean.
            if ($response->status() === 404) {
                DeviceToken::where('token', $token)->delete();
            } elseif (!$response->successful()) {
                Log::warning('FCM send failed: ' . $response->status() . ' ' . $response->body());
            }
        } catch (\Throwable $e) {
            Log::warning('FCM send exception: ' . $e->getMessage());
        }
    }

    // ── OAuth2 via service-account JWT (RS256) ─────────────────────────

    private function credentialsPath(): ?string
    {
        $configured = env('FIREBASE_CREDENTIALS');
        if (!$configured) {
            return null;
        }
        // Relative paths resolve against the Laravel base directory.
        return str_starts_with($configured, '/') || preg_match('/^[A-Za-z]:/', $configured)
            ? $configured
            : base_path($configured);
    }

    private function credentials(): ?array
    {
        $path = $this->credentialsPath();
        if (!$path || !is_readable($path)) {
            return null;
        }
        $json = json_decode((string) file_get_contents($path), true);
        return is_array($json) ? $json : null;
    }

    private function projectId(): ?string
    {
        return $this->credentials()['project_id'] ?? null;
    }

    private function accessToken(): ?string
    {
        return Cache::remember('fcm.access_token', 3000, function () {
            $creds = $this->credentials();
            if (!$creds) {
                return null;
            }

            $now = time();
            $header = $this->b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claims = $this->b64(json_encode([
                'iss' => $creds['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600,
            ]));

            $signature = '';
            $ok = openssl_sign(
                "$header.$claims",
                $signature,
                $creds['private_key'],
                OPENSSL_ALGO_SHA256
            );
            if (!$ok) {
                Log::warning('FCM: could not sign service-account JWT');
                return null;
            }

            $jwt = "$header.$claims." . $this->b64($signature);

            $response = Http::asForm()->timeout(10)->post(
                'https://oauth2.googleapis.com/token',
                [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt,
                ]
            );

            if (!$response->successful()) {
                Log::warning('FCM token exchange failed: ' . $response->body());
                return null;
            }

            return $response->json('access_token');
        });
    }

    private function b64(string $raw): string
    {
        return rtrim(strtr(base64_encode($raw), '+/', '-_'), '=');
    }
}
