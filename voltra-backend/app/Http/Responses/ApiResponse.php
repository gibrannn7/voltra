<?php

namespace App\Http\Responses;

use Illuminate\Http\JsonResponse;

class ApiResponse
{
    /**
     * Return a standardized success response.
     *
     * Envelope format:
     * {
     *   "meta": { "code": 200, "status": "success", "message": "..." },
     *   "data": { ... }
     * }
     */
    public static function success(mixed $data = null, string $message = 'OK', int $code = 200): JsonResponse
    {
        return response()->json([
            'meta' => [
                'code'    => $code,
                'status'  => 'success',
                'message' => $message,
            ],
            'data' => $data,
        ], $code);
    }

    /**
     * Return a standardized error response.
     */
    public static function error(string $message = 'Error', int $code = 400, mixed $errors = null): JsonResponse
    {
        $response = [
            'meta' => [
                'code'    => $code,
                'status'  => 'error',
                'message' => $message,
            ],
            'data' => null,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        return response()->json($response, $code);
    }

    /**
     * Return a standardized validation error response.
     */
    public static function validationError(mixed $errors, string $message = 'Validation failed'): JsonResponse
    {
        return response()->json([
            'meta' => [
                'code'    => 422,
                'status'  => 'error',
                'message' => $message,
            ],
            'data'   => null,
            'errors' => $errors,
        ], 422);
    }

    /**
     * Return a paginated success response.
     */
    public static function paginated($paginator, string $message = 'OK'): JsonResponse
    {
        return response()->json([
            'meta' => [
                'code'    => 200,
                'status'  => 'success',
                'message' => $message,
            ],
            'data' => $paginator->items(),
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
                'per_page'     => $paginator->perPage(),
                'total'        => $paginator->total(),
            ],
        ], 200);
    }
}
