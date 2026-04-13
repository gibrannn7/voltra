<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Get the authenticated user's notifications (paginated).
     *
     * GET /api/v1/notifications
     */
    public function index(Request $request): JsonResponse
    {
        $notifications = Notification::forUser($request->user()->id)
            ->orderByDesc('created_at')
            ->paginate($request->query('per_page', 20));

        $unreadCount = Notification::forUser($request->user()->id)->unread()->count();

        $formatted = $notifications->through(fn ($n) => [
            'id'         => $n->id,
            'title'      => $n->title,
            'message'    => $n->message,
            'type'       => $n->type,
            'is_read'    => $n->is_read,
            'created_at' => $n->created_at?->toIso8601String(),
        ]);

        $response = ApiResponse::paginated($formatted, 'Notifications');
        $data = json_decode($response->getContent(), true);
        $data['unread_count'] = $unreadCount;

        return response()->json($data);
    }

    /**
     * Mark a notification as read.
     *
     * PATCH /api/v1/notifications/{id}/read
     */
    public function markRead(Request $request, int $id): JsonResponse
    {
        $notification = Notification::forUser($request->user()->id)->findOrFail($id);

        $notification->update(['is_read' => true]);

        return ApiResponse::success(null, 'Notification marked as read');
    }

    /**
     * Mark all notifications as read.
     *
     * PATCH /api/v1/notifications/read-all
     */
    public function markAllRead(Request $request): JsonResponse
    {
        Notification::forUser($request->user()->id)
            ->unread()
            ->update(['is_read' => true]);

        return ApiResponse::success(null, 'All notifications marked as read');
    }
}
