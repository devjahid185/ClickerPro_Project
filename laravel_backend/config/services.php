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

    // Google Sheets auto-sync for new bookings. Disabled until both values
    // are set (see GOOGLE_SHEETS_SETUP.md). When unset the app behaves exactly
    // as before — booking saves are never blocked by Sheets.
    'google_sheets' => [
        // Absolute path to the service-account JSON key on the server.
        'credentials' => env('GOOGLE_SHEETS_CREDENTIALS'),
        // The target spreadsheet id (from its URL).
        'sheet_id' => env('GOOGLE_SHEETS_ID'),
        // Tab/sheet name to append rows to.
        'tab' => env('GOOGLE_SHEETS_TAB', 'Bookings'),
    ],

];
