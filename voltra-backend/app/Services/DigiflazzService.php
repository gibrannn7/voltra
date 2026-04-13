<?php

namespace App\Services;

use App\Models\ApiLog;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class DigiflazzService
{
    private string $username;
    private string $apiKey;
    private string $baseUrl;
    private string $webhookSecret;

    public function __construct()
    {
        $this->username      = config('services.digiflazz.username');
        $this->apiKey        = config('services.digiflazz.api_key');
        $this->baseUrl       = config('services.digiflazz.base_url');
        $this->webhookSecret = config('services.digiflazz.webhook_secret');
    }

    /**
     * Generate the MD5 signature for Digiflazz API authentication.
     *
     * Signature = md5(username + apiKey + ref_id)
     */
    private function generateSignature(string $refId): string
    {
        return md5($this->username . $this->apiKey . $refId);
    }

    /**
     * Fetch the full product/price list from Digiflazz.
     * Supports chunking for large catalogs to prevent memory exhaustion.
     *
     * @return array
     */
    public function getProducts(): array
    {
        $endpoint = '/price-list';
        $payload  = [
            'cmd'      => 'prepaid',
            'username' => $this->username,
            'sign'     => md5($this->username . $this->apiKey . 'pricelist'),
        ];

        try {
            $response = Http::timeout(30)
                ->post($this->baseUrl . $endpoint, $payload);

            $this->logRequest($endpoint, $payload, $response->json(), $response->status());

            if ($response->successful()) {
                return $response->json('data', []);
            }

            Log::error('Digiflazz getProducts failed', [
                'status'   => $response->status(),
                'response' => $response->json(),
            ]);

            return [];
        } catch (\Throwable $e) {
            Log::error('Digiflazz getProducts exception', [
                'message' => $e->getMessage(),
            ]);

            $this->logRequest($endpoint, $payload, ['error' => $e->getMessage()], 0);

            return [];
        }
    }

    /**
     * Perform a PLN inquiry (check bill / customer data).
     *
     * @param  string  $sku             Product SKU code
     * @param  string  $customerNumber  PLN meter number or phone number
     * @return array
     */
    public function inquiry(string $sku, string $customerNumber): array
    {
        $refId    = 'INQ-' . now()->format('YmdHis') . '-' . mt_rand(1000, 9999);
        $endpoint = '/transaction';
        $payload  = [
            'username'        => $this->username,
            'buyer_sku_code'  => $sku,
            'customer_no'     => $customerNumber,
            'ref_id'          => $refId,
            'sign'            => $this->generateSignature($refId),
            'testing'         => config('app.env') !== 'production',
            'msg'             => 'inquiry',
        ];

        try {
            $response = Http::timeout(30)
                ->post($this->baseUrl . $endpoint, $payload);

            $this->logRequest($endpoint, $payload, $response->json(), $response->status());

            if ($response->successful()) {
                return [
                    'success' => true,
                    'data'    => $response->json('data'),
                    'ref_id'  => $refId,
                ];
            }

            return [
                'success' => false,
                'message' => $response->json('data.message', 'Inquiry failed'),
            ];
        } catch (\Throwable $e) {
            Log::error('Digiflazz inquiry exception', [
                'message'         => $e->getMessage(),
                'customer_number' => $customerNumber,
                'sku'             => $sku,
            ]);

            $this->logRequest($endpoint, $payload, ['error' => $e->getMessage()], 0);

            return [
                'success' => false,
                'message' => 'Gagal menghubungi server aggregator. Silakan coba lagi.',
            ];
        }
    }

    /**
     * Execute a purchase transaction on Digiflazz.
     *
     * @param  string  $sku             Product SKU code
     * @param  string  $customerNumber  Target customer number
     * @param  string  $refId           Unique reference ID for idempotency
     * @return array
     */
    public function purchase(string $sku, string $customerNumber, string $refId): array
    {
        $endpoint = '/transaction';
        $payload  = [
            'username'        => $this->username,
            'buyer_sku_code'  => $sku,
            'customer_no'     => $customerNumber,
            'ref_id'          => $refId,
            'sign'            => $this->generateSignature($refId),
            'testing'         => config('app.env') !== 'production',
        ];

        try {
            $response = Http::timeout(60)
                ->post($this->baseUrl . $endpoint, $payload);

            $this->logRequest($endpoint, $payload, $response->json(), $response->status());

            if ($response->successful()) {
                $data   = $response->json('data');
                $status = strtolower($data['status'] ?? '');

                return [
                    'success' => $status === 'sukses',
                    'pending' => $status === 'pending',
                    'data'    => $data,
                    'sn'      => $data['sn'] ?? null,
                    'message' => $data['message'] ?? '',
                ];
            }

            return [
                'success' => false,
                'pending' => false,
                'message' => $response->json('data.message', 'Purchase failed'),
                'data'    => $response->json('data'),
            ];
        } catch (\Throwable $e) {
            Log::error('Digiflazz purchase exception', [
                'message' => $e->getMessage(),
                'ref_id'  => $refId,
            ]);

            $this->logRequest($endpoint, $payload, ['error' => $e->getMessage()], 0);

            return [
                'success' => false,
                'pending' => false,
                'message' => 'Gagal memproses pembelian. Silakan coba lagi.',
            ];
        }
    }

    /**
     * Manually check the status of a transaction via Digiflazz.
     *
     * @param  string  $refId  The reference ID of the transaction
     * @return array
     */
    public function checkStatus(string $refId): array
    {
        $endpoint = '/transaction';
        $payload  = [
            'username' => $this->username,
            'ref_id'   => $refId,
            'sign'     => $this->generateSignature($refId),
            'msg'      => 'status',
        ];

        try {
            $response = Http::timeout(30)
                ->post($this->baseUrl . $endpoint, $payload);

            $this->logRequest($endpoint, $payload, $response->json(), $response->status());

            return [
                'success' => $response->successful(),
                'data'    => $response->json('data'),
            ];
        } catch (\Throwable $e) {
            Log::error('Digiflazz checkStatus exception', [
                'message' => $e->getMessage(),
                'ref_id'  => $refId,
            ]);

            $this->logRequest($endpoint, $payload, ['error' => $e->getMessage()], 0);

            return [
                'success' => false,
                'message' => 'Failed to check status',
            ];
        }
    }

    /**
     * Verify the HMAC-MD5 signature from a Digiflazz webhook payload.
     *
     * The webhook secret is used as the HMAC key.
     */
    public function verifyWebhookSignature(string $receivedSignature, string $rawBody): bool
    {
        $expectedSignature = hash_hmac('md5', $rawBody, $this->webhookSecret);

        return hash_equals($expectedSignature, $receivedSignature);
    }

    /**
     * Get the current deposit balance from Digiflazz.
     *
     * @return array{success: bool, balance: float|null}
     */
    public function getBalance(): array
    {
        $endpoint = '/cek-saldo';
        $payload  = [
            'cmd'      => 'deposit',
            'username' => $this->username,
            'sign'     => md5($this->username . $this->apiKey . 'depo'),
        ];

        try {
            $response = Http::timeout(15)
                ->post($this->baseUrl . $endpoint, $payload);

            $this->logRequest($endpoint, $payload, $response->json(), $response->status());

            if ($response->successful()) {
                return [
                    'success' => true,
                    'balance' => (float) ($response->json('data.deposit') ?? 0),
                ];
            }

            return ['success' => false, 'balance' => null];
        } catch (\Throwable $e) {
            Log::error('Digiflazz getBalance exception', ['message' => $e->getMessage()]);
            return ['success' => false, 'balance' => null];
        }
    }

    /**
     * Log every API request/response to the api_logs table.
     */
    private function logRequest(string $endpoint, array $payload, ?array $response, int $httpStatus): void
    {
        try {
            ApiLog::create([
                'provider'    => ApiLog::PROVIDER_DIGIFLAZZ,
                'type'        => ApiLog::TYPE_REQUEST,
                'endpoint'    => $endpoint,
                'payload'     => $payload,
                'response'    => $response,
                'http_status' => $httpStatus,
            ]);
        } catch (\Throwable $e) {
            Log::error('Failed to log Digiflazz API call', ['error' => $e->getMessage()]);
        }
    }
}
