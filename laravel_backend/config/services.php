<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // Google Sheets auto-sync. Disabled until both credentials and sheet id
    // are set. When unset the app behaves exactly as before: app saves are
    // never blocked by Sheets.
    'google_sheets' => [
        // Absolute path to the service-account JSON key on the server.
        'credentials' => env('GOOGLE_SHEETS_CREDENTIALS'),
        // The target spreadsheet id (from its URL).
        'sheet_id' => env('GOOGLE_SHEETS_ID'),
        // Backward-compatible default tab for older code/manual calls.
        'tab' => env('GOOGLE_SHEETS_TAB', 'Bookings'),
        // Professional auto-sync tabs. The app creates/styles these if needed.
        'bookings_tab' => env('GOOGLE_SHEETS_BOOKINGS_TAB', env('GOOGLE_SHEETS_TAB', 'Bookings')),
        'payments_tab' => env('GOOGLE_SHEETS_PAYMENTS_TAB', 'Payments'),
    ],

];
