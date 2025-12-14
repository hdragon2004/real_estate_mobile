import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'signalr_service.dart';
import 'auth_storage_service.dart';

/// Service để quản lý thông báo real-time
/// Kết hợp SignalR để nhận thông báo real-time và NotificationRepository để lưu trữ
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final NotificationRepository _repository = NotificationRepository();
  final SignalRService _signalRService = SignalRService();
  
  // Stream controller để phát thông báo đến UI
  final _notificationController = StreamController<NotificationModel>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Danh sách thông báo đã nhận
  final List<NotificationModel> _notifications = [];
  bool _isInitialized = false;

  /// Stream để lắng nghe thông báo mới
  Stream<NotificationModel> get notificationStream => _notificationController.stream;
  
  /// Stream để lắng nghe tin nhắn mới
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  /// Danh sách thông báo hiện tại
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  /// Khởi tạo service - kết nối SignalR và đăng ký callbacks
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[NotificationService] Already initialized');
      return;
    }

    try {
      // Kiểm tra user đã đăng nhập chưa
      final userId = await AuthStorageService.getUserId();
      if (userId == null) {
        debugPrint('[NotificationService] User not logged in, skipping SignalR connection');
        return;
      }

      // Đăng ký callback cho NotificationHub
      _signalRService.onNotificationReceived = (notificationData) {
        _handleNotificationReceived(notificationData);
      };

      // Đăng ký callback cho MessageHub
      _signalRService.onMessageReceived = (messageData) {
        _handleMessageReceived(messageData);
      };

      // Kết nối SignalR hubs
      await _signalRService.connectAll();
      
      // Load thông báo từ server
      await _loadNotifications();
      
      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('[NotificationService] Error initializing: $e');
    }
  }

  /// Xử lý thông báo nhận được từ SignalR
  void _handleNotificationReceived(Map<String, dynamic> notificationData) {
    try {
      final notification = NotificationModel.fromJson(notificationData);
      
      // Thêm vào danh sách (ở đầu danh sách)
      _notifications.insert(0, notification);
      
      // Phát thông báo đến UI
      _notificationController.add(notification);
      
      debugPrint('[NotificationService] New notification received: ${notification.title}');
      
      // TODO: Có thể thêm local notification (flutter_local_notifications) ở đây
    } catch (e) {
      debugPrint('[NotificationService] Error handling notification: $e');
    }
  }

  /// Xử lý tin nhắn nhận được từ SignalR
  void _handleMessageReceived(Map<String, dynamic> messageData) {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: int.tryParse(messageData['fromUserId']?.toString() ?? '0') ?? 0,
        title: 'Tin nhắn mới',
        message: messageData['message']?.toString() ?? '',
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.message,
        senderId: int.tryParse(messageData['fromUserId']?.toString() ?? '0'),
      );
      
      // Thêm vào danh sách
      _notifications.insert(0, notification);
      
      // Phát thông báo đến UI
      _notificationController.add(notification);
      _messageController.add(messageData);
      
      debugPrint('[NotificationService] New message received from ${messageData['fromUserId']}');
    } catch (e) {
      debugPrint('[NotificationService] Error handling message: $e');
    }
  }

  Future<void> addLocalNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    int? postId,
    int? senderId,
    int? savedSearchId,
    int? appointmentId,
  }) async {
    try {
      final userId = await AuthStorageService.getUserId() ?? 0;
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
        type: type,
        postId: postId,
        senderId: senderId,
        savedSearchId: savedSearchId,
        appointmentId: appointmentId,
      );
      _notifications.insert(0, notification);
      _notificationController.add(notification);
    } catch (e) {
      debugPrint('[NotificationService] Error adding local notification: $e');
    }
  }

  /// Load thông báo từ server
  Future<void> _loadNotifications() async {
    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) return;
      
      final notificationsData = await _repository.getNotifications(userId);
      _notifications.clear();
      _notifications.addAll(
        notificationsData.map((data) => NotificationModel.fromJson(data)),
      );
      
      debugPrint('[NotificationService] Loaded ${_notifications.length} notifications');
    } catch (e) {
      debugPrint('[NotificationService] Error loading notifications: $e');
    }
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markAsRead(int notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      
      // Cập nhật trong danh sách
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = _notifications[index];
        _notifications[index] = NotificationModel(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          message: notification.message,
          timestamp: notification.timestamp,
          isRead: true,
          type: notification.type,
          postId: notification.postId,
          senderId: notification.senderId,
          savedSearchId: notification.savedSearchId,
          appointmentId: notification.appointmentId,
          user: notification.user,
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Error marking notification as read: $e');
    }
  }

  /// Xóa thông báo
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      
      // Xóa khỏi danh sách
      _notifications.removeWhere((n) => n.id == notificationId);
    } catch (e) {
      debugPrint('[NotificationService] Error deleting notification: $e');
    }
  }

  /// Refresh thông báo từ server
  Future<void> refresh() async {
    await _loadNotifications();
  }

  /// Đếm số thông báo chưa đọc
  int get unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  /// Ngắt kết nối SignalR (gọi khi user đăng xuất)
  Future<void> disconnect() async {
    await _signalRService.disconnectAll();
    _notifications.clear();
    _isInitialized = false;
  }

  /// Dispose resources
  void dispose() {
    _notificationController.close();
    _messageController.close();
  }
}

