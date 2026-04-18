import 'package:flutter/material.dart';
import 'package:voltra_mobile/models/notification_model.dart';
import 'package:voltra_mobile/repositories/notification_repository.dart';

/// Provider for managing state of notifications (loading, empty, list, mark as read).
class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => n.isRead == false).length;

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    if (!refresh) notifyListeners();

    try {
      final result = await _repository.getNotifications();
      _notifications = result;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      // Optimistic update
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      final success = await _repository.markAsRead(notificationId);
      if (!success) {
        // Revert on failure
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    final oldState = List<NotificationModel>.from(_notifications);
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    final success = await _repository.markAllAsRead();
    if (!success) {
      // Revert on failure
      _notifications = oldState;
      notifyListeners();
    }
  }
}