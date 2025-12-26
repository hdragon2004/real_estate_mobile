import 'dart:async';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/api_exception.dart';
import 'signalr_service.dart';
import 'auth_storage_service.dart';
import 'base_service.dart';

/// Service để quản lý thông báo real-time
/// Kết hợp SignalR để nhận thông báo real-time và NotificationRepository để lưu trữ
class NotificationService extends BaseService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final NotificationRepository _repository = NotificationRepository();
  final SignalRService _signalRService = SignalRService();
  
  // Stream controller để phát thông báo đến UI
  final _notificationController = StreamController<NotificationModel>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<ApiException>.broadcast();
  
  // Danh sách thông báo đã nhận
  final List<NotificationModel> _notifications = [];
  bool _isInitialized = false;

  /// Stream để lắng nghe thông báo mới
  Stream<NotificationModel> get notificationStream => _notificationController.stream;
  
  /// Stream để lắng nghe tin nhắn mới
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  /// Stream để lắng nghe lỗi (UI có thể subscribe để hiển thị error)
  Stream<ApiException> get errorStream => _errorController.stream;
  
  /// Danh sách thông báo hiện tại
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  @override
  void handleError(ApiException error) {
    super.handleError(error);
    // Emit error qua stream để UI có thể hiển thị
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
  }

  /// Khởi tạo service - kết nối SignalR và đăng ký callbacks
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await safeApiCall(() async {
      // Kiểm tra user đã đăng nhập chưa
      await AuthStorageService.getUserId();

      // Đăng ký callback cho NotificationHub
      _signalRService.onNotificationReceived = (notificationData) {
        _handleNotificationReceived(notificationData);
      };

      // Đăng ký callback cho MessageHub
      _signalRService.onMessageReceived = (messageData) {
        _handleMessageReceived(messageData);
      };

      // Đăng ký callback để xử lý lỗi từ SignalR
      _signalRService.onError = (message, error) {
        handleError(ApiException(
          statusCode: 0,
          message: 'SignalR: $message',
          originalError: error,
        ));
      };

      // Kết nối SignalR hubs
      await _signalRService.connectAll();
      
      // Load thông báo từ server
      await _loadNotifications();
      
      _isInitialized = true;
    });
  }

  /// Xử lý thông báo nhận được từ SignalR
  void _handleNotificationReceived(Map<String, dynamic> notificationData) {
    try {
      final notification = NotificationModel.fromJson(notificationData);
      
      final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
      if (existingIndex == -1) {
        // Chỉ thêm nếu chưa tồn tại
        _notifications.insert(0, notification);
        _notificationController.add(notification);
      } else {
        // Nếu đã tồn tại, cập nhật thông báo đó (có thể có thay đổi về isRead, etc.)
        _notifications[existingIndex] = notification;
        _notificationController.add(notification);
      }
    } catch (e) {
      handleError(ApiException(
        statusCode: 0,
        message: 'Lỗi xử lý thông báo: ${e.toString()}',
        originalError: e,
      ));
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
      
      _notifications.insert(0, notification);
      _notificationController.add(notification);
      _messageController.add(messageData);
    } catch (e) {
      handleError(ApiException(
        statusCode: 0,
        message: 'Lỗi xử lý tin nhắn: ${e.toString()}',
        originalError: e,
      ));
    }
  }

  /// Load thông báo từ server
  Future<void> _loadNotifications() async {
    final userId = await AuthStorageService.getUserId();
    if (userId == null) return;
    
    await safeApiCall(() async {
      final response = await _repository.getNotifications(userId);
      final notificationsData = unwrapListResponse(response);
      final newNotifications = notificationsData.map((data) => NotificationModel.fromJson(data)).toList();
      
      // Tạo map để dễ tìm kiếm theo ID
      final existingMap = <int, NotificationModel>{};
      for (var notification in _notifications) {
        existingMap[notification.id] = notification;
      }
      
      _notifications.clear();
      for (var notification in newNotifications) {
        _notifications.add(notification);
        existingMap.remove(notification.id); // Đánh dấu đã xử lý
      }
      
      for (var notification in existingMap.values) {
        _notifications.add(notification);
      }
      
      // Sắp xếp theo timestamp mới nhất
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markAsRead(int notificationId) async {
    await safeApiCall(() async {
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
    });
  }

  /// Xóa thông báo
  Future<void> deleteNotification(int notificationId) async {
    await safeApiCall(() async {
      await _repository.deleteNotification(notificationId);
      
      // Xóa khỏi danh sách
      _notifications.removeWhere((n) => n.id == notificationId);
    });
  }

  /// Làm mới danh sách thông báo từ server
  Future<void> refresh() async {
    await _loadNotifications();
  }

  /// Đếm số thông báo chưa đọc
  int get unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  /// Ngắt kết nối SignalR và xóa dữ liệu (gọi khi user đăng xuất)
  Future<void> disconnect() async {
    await _signalRService.disconnectAll();
    _notifications.clear();
    _isInitialized = false;
  }

  /// Dispose resources
  void dispose() {
    _notificationController.close();
    _messageController.close();
    _errorController.close();
  }
}

