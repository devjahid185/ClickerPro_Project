<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Appends booking rows to a Google Sheet using a Google service account.
 *
 * Why no google/apiclient package: that SDK pulls in a large dependency tree
 * and can be awkward to install on shared cPanel hosting. Instead this talks
 * to the Sheets REST API directly with Laravel's HTTP client, minting a short
 * OAuth2 access token from the service-account key via a signed JWT. Pure PHP
 * (openssl + http) — nothing extra to `composer require`.
 *
 * Setup (see GOOGLE_SHEETS_SETUP.md):
 *   1. Create a Google Cloud service account, enable the Sheets API.
 *   2. Download its JSON key, save it on the server, point
 *      GOOGLE_SHEETS_CREDENTIALS at the path.
 *   3. Share the target spreadsheet with the service account's email
 *      (Editor), set GOOGLE_SHEETS_ID to the spreadsheet id.
 *
 * Every method is fail-safe: any error is logged and swallowed so a Sheets
 * outage never blocks a booking from being saved.
 */
class GoogleSheetsService
{
    private const TOKEN_URL = 'https://oauth2.googleapis.com/token';
    private const SCOPE = 'https://www.googleapis.com/auth/spreadsheets';
    private const TOKEN_CACHE_KEY = 'google_sheets_access_token';

    /** True only when both the credentials file and a sheet id are configured. */
    public function isEnabled(): bool
    {
        $path = (string) config('services.google_sheets.credentials');
        $sheetId = (string) config('services.google_sheets.sheet_id');

        return $path !== '' && $sheetId !== '' && is_file($path);
    }

    /**
     * Append a single row to the configured sheet.
     *
     * @param array<int, scalar|null> $row Cell values, left to right.
     * @param string $tab The sheet/tab name to append to (default "Bookings").
     */
    public function appendRow(array $row, string $tab = 'Bookings'): bool
    {
        if (!$this->isEnabled()) {
            return false;
        }

        try {
            $token = $this->accessToken();
            if ($token === null) {
                return false;
            }

            $sheetId = (string) config('services.google_sheets.sheet_id');
            $range = rawurlencode($tab) . '!A1';
            $url = "https://sheets.googleapis.com/v4/spreadsheets/{$sheetId}"
                . "/values/{$range}:append"
                . '?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS';

            $resp = Http::withToken($token)
                ->timeout(15)
                ->post($url, ['values' => [$row]]);

            if ($resp->failed()) {
                Log::warning('GoogleSheets append failed', [
                    'status' => $resp->status(),
                    'body' => $resp->body(),
                ]);
                return false;
            }

            return true;
        } catch (\Throwable $e) {
            Log::warning('GoogleSheets append threw', ['error' => $e->getMessage()]);
            return false;
        }
    }

    /**
     * Mint (and cache) an OAuth2 access token from the service-account key.
     * Tokens last 1h; we cache for 55m to stay safely fresh.
     */
    private function accessToken(): ?string
    {
        $cached = Cache::get(self::TOKEN_CACHE_KEY);
        if (is_string($cached) && $cached !== '') {
            return $cached;
        }

        $creds = $this->credentials();
        if ($creds === null) {
            return null;
        }

        $now = time();
        $jwt = $this->signJwt([
            'iss' => $creds['client_email'],
            'scope' => self::SCOPE,
            'aud' => self::TOKEN_URL,
            'iat' => $now,
            'exp' => $now + 3600,
        ], $creds['private_key']);

        if ($jwt === null) {
            return null;
        }

        $resp = Http::asForm()->timeout(15)->post(self::TOKEN_URL, [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        if ($resp->failed()) {
            Log::warning('GoogleSheets token request failed', [
                'status' => $resp->status(),
                'body' => $resp->body(),
            ]);
            return null;
        }

        $token = (string) $resp->json('access_token', '');
        if ($token === '') {
            return null;
        }

        Cache::put(self::TOKEN_CACHE_KEY, $token, now()->addMinutes(55));
        return $token;
    }

    /** Load + validate the service-account JSON key. */
    private function credentials(): ?array
    {
        $path = (string) config('services.google_sheets.credentials');
        if ($path === '' || !is_file($path)) {
            return null;
        }

        $json = json_decode((string) file_get_contents($path), true);
        if (!is_array($json)
            || empty($json['client_email'])
            || empty($json['private_key'])) {
            Log::warning('GoogleSheets credentials file is invalid');
            return null;
        }

        return $json;
    }

    /** Build a signed RS256 JWT for the OAuth2 token exchange. */
    private function signJwt(array $claims, string $privateKey): ?string
    {
        $header = $this->base64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $payload = $this->base64Url(json_encode($claims));
        $signingInput = "{$header}.{$payload}";

        $signature = '';
        $ok = openssl_sign($signingInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        if (!$ok) {
            Log::warning('GoogleSheets JWT signing failed');
            return null;
        }

        return "{$signingInput}." . $this->base64Url($signature);
    }

    private function base64Url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
