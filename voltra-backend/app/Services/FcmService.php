<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    private string $serverKey;
    private string $projectId;
    private string $fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    public function __construct()
    {
        $this->serverKey = config('services.fcm.server_key');
        $this->projectId = config('services.fcm.project_id');
    }

    /**
     * Send a push notification to a specific user and persist it in the database.
     *
     * @param  User    $user     Target user
     * @param  string  $title    Notification title
     * @param  string  $message  Notification body
     * @param  string  $type     Notification type: promo, reminder, transaction
     * @param  array   $data     Additional data payload
     * @return bool
     */
    public function sendToUser(User $user, string $title, string $message, string $type = 'transaction', array $data = []): bool
    {
        // Always persist the notification in the database
        Notification::create([
            'user_id' => $user->id,
            'title'   => $title,
            'message' => $message,
            'type'    => $type,
            'is_read' => false,
        ]);

        // If user has no FCM token, skip the push but the DB notification is saved
        if (empty($user->fcm_token)) {
            Log::info('FCM: No token for user', ['user_id' => $user->id]);
            return false;
        }

        return $this->sendPush($user->fcm_token, $title, $message, $data);
    }

    /**
     * Send a push notification to a topic (e.g., 'all_users', 'promos').
     *
     * @param  string  $topic    FCM topic name
     * @param  string  $title    Notification title
     * @param  string  $message  Notification body
     * @param  array   $data     Additional data payload
     * @return bool
     */
    public function sendToTopic(string $topic, string $title, string $message, array $data = []): bool
    {
        $payload = [
            'to' => "/topics/{$topic}",
            'notification' => [
                'title' => $title,
                'body'  => $message,
                'sound' => 'default',
            ],
            'data' => $data,
        ];

        return $this->fireRequest($payload);
    }

    /**
     * Send push notification to a device token.
     */
    private function sendPush(string $token, string $title, string $message, array $data = []): bool
    {
        $payload = [
            'to' => $token,
            'notification' => [
                'title' => $title,
                'body'  => $message,
                'sound' => 'default',
            ],
            'data' => $data,
        ];

        return $this->fireRequest($payload);
    }

    /**
     * Execute the FCM HTTP request.
     */
    private function fireRequest(array $payload): bool
    {
        if (empty($this->serverKey)) {
            Log::warning('FCM server key is not configured');
            return false;
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $this->serverKey,
                'Content-Type'  => 'application/json',
            ])
                ->timeout(10)
                ->post($this->fcmUrl, $payload);

            if ($response->successful() && $response->json('success') >= 1) {
                return true;
            }

            Log::warning('FCM push failed', [
                'response' => $response->json(),
            ]);

            return false;
        } catch (\Throwable $e) {
            Log::error('FCM exception', ['message' => $e->getMessage()]);
            return false;
        }
    }
}
