import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repo = NotificationRepository();

  bool _isLoading = false;
  List<NotificationModel> _notifications = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<NotificationModel> get notifications => _notifications;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    final result = await _repo.getNotifications();
    if (result.isSuccess && result.data != null) {
      _notifications = result.data!;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    await _repo.markAsRead(id.toString());
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      fetchNotifications();
    }
  }
}