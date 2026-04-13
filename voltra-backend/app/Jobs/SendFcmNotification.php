<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\FcmService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendFcmNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 10;

    public function __construct(
        private int $userId,
        private string $title,
        private string $message,
        private string $type = 'transaction',
        private array $data = [],
    ) {}

    /**
     * Send an FCM push notification to a user.
     * Dispatched asynchronously to avoid blocking the main request.
     */
    public function handle(FcmService $fcmService): void
    {
        $user = User::find($this->userId);

        if (! $user) {
            Log::warning('SendFcmNotification: User not found', ['user_id' => $this->userId]);
            return;
        }

        $fcmService->sendToUser($user, $this->title, $this->message, $this->type, $this->data);

        Log::info('SendFcmNotification: Sent', [
            'user_id' => $this->userId,
            'title'   => $this->title,
        ]);
    }
}
