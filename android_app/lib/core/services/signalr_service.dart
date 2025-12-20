import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../config/app_config.dart';
import 'auth_storage_service.dart';

/// Service để kết nối với SignalR Hubs (NotificationHub và MessageHub)
/// Nhận thông báo real-time từ backend
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _notificationHub;
  HubConnection? _messageHub;
  bool _isNotificationHubConnected = false;
  bool _isMessageHubConnected = false;

  // Callbacks cho notifications và messages
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(Map<String, dynamic>)? onMessageReceived;

  Future<void> connectNotificationHub() async {
    if (kIsWeb) {
      debugPrint('[SignalR] NotificationHub is disabled on Web platform');
      return;
    }
    if (_isNotificationHubConnected && _notificationHub != null) {
      debugPrint('[SignalR] NotificationHub already connected');
      return;
    }

    try {
      final token = await AuthStorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[SignalR] No token found, cannot connect to NotificationHub');
        return;
      }

      // Tạo connection với JWT token trong query string
      // SignalR backend nhận token từ query string "access_token"
      // Lấy base URL và bỏ /api vì SignalR hub không có /api prefix
      final baseUrl = AppConfig.baseUrl.replaceAll('/api', '');
      final hubUrl = '$baseUrl/notificationHub?access_token=$token';
      
      // Tạo HttpConnectionOptions với accessTokenFactory
      final httpOptions = HttpConnectionOptions(
        accessTokenFactory: () async => token,
      );
      
      _notificationHub = HubConnectionBuilder()
          .withUrl(hubUrl, options: httpOptions)
          .build();

      // Đăng ký callback để nhận notifications
      _notificationHub!.on('ReceiveNotification', (arguments) {
        try {
          if (arguments != null && arguments.isNotEmpty) {
            // SignalR gửi object, cần parse thành Map
            final notification = arguments[0];
            Map<String, dynamic> notificationMap;
            
            if (notification is Map) {
              notificationMap = Map<String, dynamic>.from(notification);
            } else if (notification is String) {
              notificationMap = json.decode(notification) as Map<String, dynamic>;
            } else {
              debugPrint('[SignalR] Unknown notification format: $notification');
              return;
            }
            
            debugPrint('[SignalR] Received notification: $notificationMap');
            onNotificationReceived?.call(notificationMap);
          }
        } catch (e) {
          debugPrint('[SignalR] Error parsing notification: $e');
        }
      });

      // Xử lý connection events
      _notificationHub!.onclose(({Exception? error}) {
        _isNotificationHubConnected = false;
        debugPrint('[SignalR] NotificationHub disconnected: $error');
        // Tự động reconnect sau 3 giây
        Future.delayed(const Duration(seconds: 3), () {
          if (!_isNotificationHubConnected) {
            connectNotificationHub();
          }
        });
      });

      // Bắt đầu kết nối
      await _notificationHub!.start();
      _isNotificationHubConnected = true;
      debugPrint('[SignalR] NotificationHub connected successfully');
    } catch (e) {
      _isNotificationHubConnected = false;
      debugPrint('[SignalR] Error connecting to NotificationHub: $e');
      // Retry sau 5 giây
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isNotificationHubConnected) {
          connectNotificationHub();
        }
      });
    }
  }

  Future<void> connectMessageHub() async {
    if (kIsWeb) {
      debugPrint('[SignalR] MessageHub is disabled on Web platform');
      return;
    }
    if (_isMessageHubConnected && _messageHub != null) {
      debugPrint('[SignalR] MessageHub already connected');
      return;
    }

    try {
      final token = await AuthStorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[SignalR] No token found, cannot connect to MessageHub');
        return;
      }

      // Tạo connection với JWT token trong query string
      // Lấy base URL và bỏ /api vì SignalR hub không có /api prefix
      final baseUrl = AppConfig.baseUrl.replaceAll('/api', '');
      final hubUrl = '$baseUrl/messageHub?access_token=$token';
      
      // Tạo HttpConnectionOptions với accessTokenFactory
      final httpOptions = HttpConnectionOptions(
        accessTokenFactory: () async => token,
      );
      
      _messageHub = HubConnectionBuilder()
          .withUrl(hubUrl, options: httpOptions)
          .build();

      // Đăng ký callback để nhận messages
      _messageHub!.on('ReceiveMessage', (arguments) {
        try {
          if (arguments != null && arguments.length >= 2) {
            final fromUserId = arguments[0].toString();
            final message = arguments[1].toString();
            debugPrint('[SignalR] Received message from $fromUserId: $message');
            onMessageReceived?.call({
              'fromUserId': fromUserId,
              'message': message,
            });
          }
        } catch (e) {
          debugPrint('[SignalR] Error parsing message: $e');
        }
      });

      // Xử lý connection events
      _messageHub!.onclose(({Exception? error}) {
        _isMessageHubConnected = false;
        debugPrint('[SignalR] MessageHub disconnected: $error');
        // Tự động reconnect sau 3 giây
        Future.delayed(const Duration(seconds: 3), () {
          if (!_isMessageHubConnected) {
            connectMessageHub();
          }
        });
      });

      // Bắt đầu kết nối
      await _messageHub!.start();
      _isMessageHubConnected = true;
      debugPrint('[SignalR] MessageHub connected successfully');
    } catch (e) {
      _isMessageHubConnected = false;
      debugPrint('[SignalR] Error connecting to MessageHub: $e');
      // Retry sau 5 giây
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isMessageHubConnected) {
          connectMessageHub();
        }
      });
    }
  }

  /// Kết nối tất cả hubs (gọi sau khi user đăng nhập)
  Future<void> connectAll() async {
    await connectNotificationHub();
    await connectMessageHub();
  }

  /// Ngắt kết nối tất cả hubs (gọi khi user đăng xuất)
  Future<void> disconnectAll() async {
    try {
      if (_notificationHub != null) {
        await _notificationHub!.stop();
        _isNotificationHubConnected = false;
        debugPrint('[SignalR] NotificationHub disconnected');
      }
      if (_messageHub != null) {
        await _messageHub!.stop();
        _isMessageHubConnected = false;
        debugPrint('[SignalR] MessageHub disconnected');
      }
    } catch (e) {
      debugPrint('[SignalR] Error disconnecting: $e');
    }
  }

  /// Kiểm tra trạng thái kết nối
  bool get isNotificationHubConnected => _isNotificationHubConnected;
  bool get isMessageHubConnected => _isMessageHubConnected;
}
