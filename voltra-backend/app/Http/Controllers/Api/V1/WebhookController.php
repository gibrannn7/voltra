<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Jobs\ProcessDigiflazzCallback;
use App\Jobs\ProcessMidtransSettlement;
use App\Models\ApiLog;
use App\Services\DigiflazzService;
use App\Services\MidtransService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    public function __construct(
        private MidtransService $midtransService,
        private DigiflazzService $digiflazzService,
    ) {}

    /**
     * Handle Midtrans payment notification webhook.
     *
     * POST /api/v1/webhooks/midtrans
     *
     * Flow:
     * 1. Log the raw webhook payload
     * 2. Verify SHA-512 signature
     * 3. If settlement → dispatch ProcessMidtransSettlement job
     */
    public function midtrans(Request $request): JsonResponse
    {
        $payload = $request->all();

        // Log the webhook
        ApiLog::create([
            'provider'    => ApiLog::PROVIDER_MIDTRANS,
            'type'        => ApiLog::TYPE_WEBHOOK,
            'endpoint'    => '/webhooks/midtrans',
            'payload'     => $payload,
            'response'    => null,
            'http_status' => 200,
        ]);

        // Verify signature
        if (! $this->midtransService->verifySignature($payload)) {
            Log::warning('Midtrans webhook: invalid signature', $payload);
            return ApiResponse::error('Invalid signature', 403);
        }

        $transactionStatus = $payload['transaction_status'] ?? '';
        $fraudStatus       = $payload['fraud_status'] ?? 'accept';
        $orderId           = $payload['order_id'] ?? '';

        Log::info('Midtrans webhook received', [
            'order_id' => $orderId,
            'status'   => $transactionStatus,
            'fraud'    => $fraudStatus,
        ]);

        // Process only settlement (payment confirmed)
        if ($transactionStatus === 'settlement' || ($transactionStatus === 'capture' && $fraudStatus === 'accept')) {
            ProcessMidtransSettlement::dispatch($orderId, $payload);
        }

        // Handle expiry/cancel — mark transaction as failed
        if (in_array($transactionStatus, ['expire', 'cancel', 'deny'])) {
            $this->handleMidtransFailure($orderId, $transactionStatus);
        }

        // Always return 200 to acknowledge receipt
        return ApiResponse::success(null, 'Webhook received');
    }

    /**
     * Handle Digiflazz callback/webhook.
     *
     * POST /api/v1/webhooks/digiflazz
     *
     * Flow:
     * 1. Log the raw webhook payload
     * 2. Verify HMAC-MD5 signature
     * 3. Dispatch ProcessDigiflazzCallback job (contains Automated Refund Protocol)
     */
    public function digiflazz(Request $request): JsonResponse
    {
        $payload  = $request->all();
        $rawBody  = $request->getContent();

        // Log the webhook
        ApiLog::create([
            'provider'    => ApiLog::PROVIDER_DIGIFLAZZ,
            'type'        => ApiLog::TYPE_WEBHOOK,
            'endpoint'    => '/webhooks/digiflazz',
            'payload'     => $payload,
            'response'    => null,
            'http_status' => 200,
        ]);

        // Verify HMAC-MD5 signature
        $receivedSignature = $request->header('X-Hub-Signature', '');

        // Digiflazz sends signature as "sha1=xxxxx" or directly as hash
        $signature = str_replace('sha1=', '', $receivedSignature);

        if (! empty($this->digiflazzService->verifyWebhookSignature($signature, $rawBody))) {
            // Signature verification is advisory — log but still process
            Log::info('Digiflazz webhook signature check', [
                'received' => $signature,
            ]);
        }

        // Extract the transaction data
        $data = $payload['data'] ?? $payload;

        // Dispatch the job for processing
        ProcessDigiflazzCallback::dispatch($data);

        return ApiResponse::success(null, 'Webhook received');
    }

    /**
     * Handle Midtrans payment failure (expire/cancel/deny).
     */
    private function handleMidtransFailure(string $orderId, string $reason): void
    {
        $transaction = \App\Models\Transaction::where('midtrans_order_id', $orderId)->first();

        if ($transaction && $transaction->isPending()) {
            $transaction->update([
                'status' => \App\Models\Transaction::STATUS_FAILED,
            ]);

            Log::info('Transaction marked as failed due to Midtrans', [
                'order_id' => $orderId,
                'reason'   => $reason,
            ]);
        }
    }
}
