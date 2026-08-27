<?php

namespace App\Services;

use App\Models\Event;
use App\Models\Payment;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Appends professional, print-friendly rows to Google Sheets using a Google
 * service account. Fail-safe: Sheets errors are logged and never block app data.
 */
class GoogleSheetsService
{
    private const TOKEN_URL = 'https://oauth2.googleapis.com/token';
    private const SCOPE = 'https://www.googleapis.com/auth/spreadsheets';
    private const TOKEN_CACHE_KEY = 'google_sheets_access_token';

    private const BOOKING_HEADERS = [
        'Action', 'Booking ID', 'Updated At', 'Created At', 'Event Date',
        'Title', 'Type', 'Client', 'Phone', 'Bride', 'Groom', 'Venue',
        'Shift', 'Status', 'Package Price', 'Advance Paid', 'Due Amount',
        'Reporting Time', 'Start Time', 'End Time', 'Chief Photographer',
        'Notes',
    ];

    private const PAYMENT_HEADERS = [
        'Action', 'Payment ID', 'Booking ID', 'Updated At', 'Paid At',
        'Event Date', 'Booking Title', 'Client', 'Kind', 'Method', 'Amount',
        'Booking Price', 'Advance Paid', 'Due Amount', 'Note',
    ];

    public function isEnabled(): bool
    {
        $path = (string) config('services.google_sheets.credentials');
        $sheetId = (string) config('services.google_sheets.sheet_id');

        return $path !== '' && $sheetId !== '' && is_file($path);
    }

    public function appendBooking(Event $event, string $action = 'CREATED'): bool
    {
        $event->loadMissing('client');

        return $this->appendRow([
            $action,
            $event->id,
            now()->toDateTimeString(),
            optional($event->created_at)->toDateTimeString(),
            optional($event->date)->toDateString(),
            $event->title,
            $event->event_type,
            optional($event->client)->name,
            optional($event->client)->phone,
            $event->bride_name,
            $event->groom_name,
            $event->venue,
            $event->shift,
            $event->status,
            $event->price,
            $event->advance_paid,
            $event->due_amount,
            $event->reporting_time,
            $event->start_time,
            $event->end_time,
            $event->chief_photographer_name,
            $event->notes,
        ], (string) config('services.google_sheets.bookings_tab', 'Bookings'), self::BOOKING_HEADERS);
    }

    public function appendPayment(Payment $payment, string $action = 'CREATED'): bool
    {
        $payment->loadMissing('event.client');
        $event = $payment->event;

        return $this->appendRow([
            $action,
            $payment->id,
            $payment->event_id,
            now()->toDateTimeString(),
            optional($payment->paid_at)->toDateTimeString(),
            optional($event?->date)->toDateString(),
            $event?->title,
            optional($event?->client)->name,
            $payment->kind,
            $payment->method,
            $payment->amount,
            $event?->price,
            $event?->advance_paid,
            $event?->due_amount,
            $payment->note,
        ], (string) config('services.google_sheets.payments_tab', 'Payments'), self::PAYMENT_HEADERS);
    }

    /**
     * Append a single row to the configured sheet.
     *
     * @param array<int, scalar|null> $row Cell values, left to right.
     * @param array<int, string> $headers Optional header row to create/style.
     */
    public function appendRow(array $row, string $tab = 'Bookings', array $headers = []): bool
    {
        if (!$this->isEnabled()) {
            return false;
        }

        try {
            $token = $this->accessToken();
            if ($token === null) {
                return false;
            }

            if ($headers !== []) {
                $this->prepareTab($token, $tab, $headers);
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
                    'tab' => $tab,
                    'status' => $resp->status(),
                    'body' => $resp->body(),
                ]);
                return false;
            }

            return true;
        } catch (\Throwable $e) {
            Log::warning('GoogleSheets append threw', [
                'tab' => $tab,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    private function prepareTab(string $token, string $tab, array $headers): void
    {
        $sheetId = (string) config('services.google_sheets.sheet_id');
        $cacheKey = 'google_sheets_prepared_' . md5($sheetId . '|' . $tab . '|' . implode('|', $headers));
        if (Cache::get($cacheKey)) {
            return;
        }

        $sheet = $this->sheetProperties($token, $tab);
        if ($sheet === null) {
            $this->addSheet($token, $tab, count($headers));
            $sheet = $this->sheetProperties($token, $tab);
        }
        if ($sheet === null) {
            return;
        }

        $this->writeHeaders($token, $tab, $headers);
        $this->styleSheet($token, (int) $sheet['sheetId'], count($headers));
        Cache::put($cacheKey, true, now()->addHours(12));
    }

    private function sheetProperties(string $token, string $tab): ?array
    {
        $sheetId = (string) config('services.google_sheets.sheet_id');
        $url = "https://sheets.googleapis.com/v4/spreadsheets/{$sheetId}?fields=sheets(properties(sheetId,title))";
        $resp = Http::withToken($token)->timeout(15)->get($url);
        if ($resp->failed()) {
            Log::warning('GoogleSheets metadata failed', [
                'tab' => $tab,
                'status' => $resp->status(),
                'body' => $resp->body(),
            ]);
            return null;
        }

        foreach ((array) $resp->json('sheets', []) as $sheet) {
            $props = $sheet['properties'] ?? [];
            if (($props['title'] ?? null) === $tab) {
                return $props;
            }
        }

        return null;
    }

    private function addSheet(string $token, string $tab, int $columnCount): void
    {
        $sheetId = (string) config('services.google_sheets.sheet_id');
        $url = "https://sheets.googleapis.com/v4/spreadsheets/{$sheetId}:batchUpdate";
        $resp = Http::withToken($token)->timeout(15)->post($url, [
            'requests' => [[
                'addSheet' => [
                    'properties' => [
                        'title' => $tab,
                        'gridProperties' => [
                            'rowCount' => 1000,
                            'columnCount' => max($columnCount, 12),
                            'frozenRowCount' => 1,
                        ],
                    ],
                ],
            ]],
        ]);

        if ($resp->failed()) {
            Log::warning('GoogleSheets add sheet failed', [
                'tab' => $tab,
                'status' => $resp->status(),
                'body' => $resp->body(),
            ]);
        }
    }

    private function writeHeaders(string $token, string $tab, array $headers): void
    {
        $sheetId = (string) config('services.google_sheets.sheet_id');
        $range = rawurlencode($tab) . '!A1';
        $url = "https://sheets.googleapis.com/v4/spreadsheets/{$sheetId}/values/{$range}"
            . '?valueInputOption=USER_ENTERED';
        $resp = Http::withToken($token)->timeout(15)->put($url, [
            'values' => [$headers],
        ]);

        if ($resp->failed()) {
            Log::warning('GoogleSheets header write failed', [
                'tab' => $tab,
                'status' => $resp->status(),
                'body' => $resp->body(),
            ]);
        }
    }

    private function styleSheet(string $token, int $sheetNumericId, int $columnCount): void
    {
        $sheetId = (string) config('services.google_sheets.sheet_id');
        $url = "https://sheets.googleapis.com/v4/spreadsheets/{$sheetId}:batchUpdate";
        $resp = Http::withToken($token)->timeout(15)->post($url, [
            'requests' => [
                [
                    'updateSheetProperties' => [
                        'properties' => [
                            'sheetId' => $sheetNumericId,
                            'gridProperties' => ['frozenRowCount' => 1],
                        ],
                        'fields' => 'gridProperties.frozenRowCount',
                    ],
                ],
                [
                    'repeatCell' => [
                        'range' => [
                            'sheetId' => $sheetNumericId,
                            'startRowIndex' => 0,
                            'endRowIndex' => 1,
                            'startColumnIndex' => 0,
                            'endColumnIndex' => $columnCount,
                        ],
                        'cell' => [
                            'userEnteredFormat' => [
                                'backgroundColor' => [
                                    'red' => 0.05,
                                    'green' => 0.12,
                                    'blue' => 0.22,
                                ],
                                'horizontalAlignment' => 'CENTER',
                                'textFormat' => [
                                    'foregroundColor' => [
                                        'red' => 1,
                                        'green' => 1,
                                        'blue' => 1,
                                    ],
                                    'bold' => true,
                                ],
                            ],
                        ],
                        'fields' => 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
                    ],
                ],
                [
                    'setBasicFilter' => [
                        'filter' => [
                            'range' => [
                                'sheetId' => $sheetNumericId,
                                'startRowIndex' => 0,
                                'startColumnIndex' => 0,
                                'endColumnIndex' => $columnCount,
                            ],
                        ],
                    ],
                ],
                [
                    'autoResizeDimensions' => [
                        'dimensions' => [
                            'sheetId' => $sheetNumericId,
                            'dimension' => 'COLUMNS',
                            'startIndex' => 0,
                            'endIndex' => $columnCount,
                        ],
                    ],
                ],
            ],
        ]);

        if ($resp->failed()) {
            Log::warning('GoogleSheets style failed', [
                'sheet_id' => $sheetNumericId,
                'status' => $resp->status(),
                'body' => $resp->body(),
            ]);
        }
    }

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
