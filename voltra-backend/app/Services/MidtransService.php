<?php

namespace App\Services;

use App\Models\ApiLog;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MidtransService
{
    private string $serverKey;
    private string $clientKey;
    private bool   $isProduction;
    private string $snapUrl;
    private string $baseUrl;

    public function __construct()
    {
        $this->serverKey    = config('services.midtrans.server_key');
        $this->clientKey    = config('services.midtrans.client_key');
        $this->isProduction = (bool) config('services.midtrans.is_production');
        $this->snapUrl      = config('services.midtrans.snap_url');
        $this->baseUrl      = config('services.midtrans.base_url');
    }

    /**
     * Create a Snap transaction and return the payment URL/token.
     *
     * @param  string  $orderId    Unique order identifier
     * @param  string  $amount     Transaction amount (uses string for precision)
     * @param  array   $userData   User details: name, email, phone
     * @return array
     */
    public function createSnapTransaction(string $orderId, string $amount, array $userData): array
    {
        $endpoint = '/transactions';
        $payload  = [
            'transaction_details' => [
                'order_id'     => $orderId,
                'gross_amount' => (int) $amount,
            ],
            'customer_details' => [
                'first_name' => $userData['name'] ?? 'Voltra User',
                'email'      => $userData['email'] ?? 'user@voltra.app',
                'phone'      => $userData['phone'] ?? '',
            ],
            'callbacks' => [
                'finish' => config('app.url') . '/api/v1/midtrans/finish',
            ],
        ];

        try {
            $response = Http::withBasicAuth($this->serverKey, '')
                ->timeout(30)
                ->post($this->snapUrl . $endpoint, $payload);

            $this->logRequest($endpoint, $payload, $response->json(), $response->status());

            if ($response->successful()) {
                return [
                    'success'      => true,
                    'snap_token'   => $response->json('token'),
                    'redirect_url' => $response->json('redirect_url'),
                ];
            }

            return [
                'success' => false,
                'message' => $response->json('error_messages.0', 'Failed to create payment'),
            ];
        } catch (\Throwable $e) {
            Log::error('Midtrans createSnapTransaction exception', [
                'message'  => $e->getMessage(),
                'order_id' => $orderId,
            ]);

            $this->logRequest($endpoint, $payload, ['error' => $e->getMessage()], 0);

            return [
                'success' => false,
                'message' => 'Gagal menghubungi payment gateway. Silakan coba lagi.',
            ];
        }
    }

    /**
     * Verify the webhook notification signature from Midtrans.
     *
     * SHA-512(order_id + status_code + gross_amount + server_key)
     */
    public function verifySignature(array $payload): bool
    {
        $orderId     = $payload['order_id'] ?? '';
        $statusCode  = $payload['status_code'] ?? '';
        $grossAmount = $payload['gross_amount'] ?? '';
        $signature   = $payload['signature_key'] ?? '';

        $expectedSignature = hash(
            'sha512',
            $orderId . $statusCode . $grossAmount . $this->serverKey
        );

        return hash_equals($expectedSignature, $signature);
    }

    /**
     * Manually check the transaction status on Midtrans.
     *
     * @param  string  $orderId  The Midtrans order ID
     * @return array
     */
    public function checkTransactionStatus(string $orderId): array
    {
        $endpoint = "/{$orderId}/status";

        try {
            $response = Http::withBasicAuth($this->serverKey, '')
                ->timeout(15)
                ->get($this->baseUrl . $endpoint);

            $this->logRequest($endpoint, ['order_id' => $orderId], $response->json(), $response->status());

            if ($response->successful()) {
                $data = $response->json();

                return [
                    'success'            => true,
                    'transaction_status' => $data['transaction_status'] ?? null,
                    'fraud_status'       => $data['fraud_status'] ?? null,
                    'payment_type'       => $data['payment_type'] ?? null,
                    'data'               => $data,
                ];
            }

            return [
                'success' => false,
                'message' => $response->json('status_message', 'Status check failed'),
            ];
        } catch (\Throwable $e) {
            Log::error('Midtrans checkTransactionStatus exception', [
                'message'  => $e->getMessage(),
                'order_id' => $orderId,
            ]);

            $this->logRequest($endpoint, ['order_id' => $orderId], ['error' => $e->getMessage()], 0);

            return [
                'success' => false,
                'message' => 'Failed to check payment status',
            ];
        }
    }

    /**
     * Get the Midtrans client key (safe to expose to frontend/mobile).
     */
    public function getClientKey(): string
    {
        return $this->clientKey;
    }

    /**
     * Log every API interaction to the api_logs table.
     */
    private function logRequest(string $endpoint, array $payload, ?array $response, int $httpStatus): void
    {
        try {
            // Sanitize: never log the server key
            $sanitizedPayload = $payload;
            unset($sanitizedPayload['server_key']);

            ApiLog::create([
                'provider'    => ApiLog::PROVIDER_MIDTRANS,
                'type'        => ApiLog::TYPE_REQUEST,
                'endpoint'    => $endpoint,
                'payload'     => $sanitizedPayload,
                'response'    => $response,
                'http_status' => $httpStatus,
            ]);
        } catch (\Throwable $e) {
            Log::error('Failed to log Midtrans API call', ['error' => $e->getMessage()]);
        }
    }
}
