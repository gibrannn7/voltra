<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    */

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
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

    /*
    |--------------------------------------------------------------------------
    | Digiflazz PPOB Aggregator
    |--------------------------------------------------------------------------
    */

    'digiflazz' => [
        'username'       => env('DIGIFLAZZ_USERNAME'),
        'api_key'        => env('DIGIFLAZZ_API_KEY'),
        'webhook_secret' => env('DIGIFLAZZ_WEBHOOK_SECRET'),
        'base_url'       => env('DIGIFLAZZ_BASE_URL', 'https://api.digiflazz.com/v1'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Midtrans Payment Gateway
    |--------------------------------------------------------------------------
    */

    'midtrans' => [
        'server_key'    => env('MIDTRANS_SERVER_KEY'),
        'client_key'    => env('MIDTRANS_CLIENT_KEY'),
        'is_production' => env('MIDTRANS_IS_PRODUCTION', false),
        'snap_url'      => env('MIDTRANS_SNAP_URL', 'https://app.sandbox.midtrans.com/snap/v1'),
        'base_url'      => env('MIDTRANS_BASE_URL', 'https://api.sandbox.midtrans.com/v2'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Firebase Cloud Messaging
    |--------------------------------------------------------------------------
    */

    'fcm' => [
        'server_key' => env('FCM_SERVER_KEY'),
        'project_id'  => env('FCM_PROJECT_ID'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Customer Service WhatsApp
    |--------------------------------------------------------------------------
    */

    'whatsapp_cs' => [
        'phone_number' => env('CS_WHATSAPP_NUMBER', '6281234567890'),
    ],

];
