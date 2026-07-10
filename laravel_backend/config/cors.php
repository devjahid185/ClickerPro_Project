<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],

    // Origins come from CORS_ALLOWED_ORIGINS (comma-separated) in production,
    // e.g. "https://app.yourdomain.com,https://admin.yourdomain.com".
    //
    // Default is "*" (any origin). This API is safe to open: it authenticates
    // with bearer tokens in the Authorization header, NOT cookies, and
    // `supports_credentials` is false — so a hostile page can't ride a logged-in
    // session, it would need to steal the token first. The self-booking page is
    // served from the web-app host (app.<domain>) and POSTs to the API host
    // (api.<domain>); a locked allow-list silently broke every client
    // submission ("ApiException status:0 Network error"). "*" also survives a
    // domain rename (deyalghori → graphy7) without a redeploy. Set
    // CORS_ALLOWED_ORIGINS to a concrete list if you ever want to tighten this.
    'allowed_origins' => array_filter(array_map(
        'trim',
        explode(',', env('CORS_ALLOWED_ORIGINS', '*'))
    )),

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    // Auth uses bearer tokens (not cookies), so credentialed CORS is not needed.
    'supports_credentials' => false,

];
