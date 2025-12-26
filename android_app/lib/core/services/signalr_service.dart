import 'dart:async';
import 'dart:convert';
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
  
  // Callback để xử lý lỗi tập trung
  Function(String message, dynamic error)? onError;

  // Retry configuration
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _retryDelay = Duration(seconds: 5);

  /// Helper generic để kết nối SignalR hub
  /// Giảm code lặp giữa connectNotificationHub và connectMessageHub
  Future<HubConnection?> _connectHub({
    required String hubPath,
    required String eventName,
    required Function(Map<String, dynamic>) onReceived,
    required bool Function() isConnected,
    required void Function(bool) setConnected,
    required HubConnection? Function() getHub,
    required void Function(HubConnection?) setHub,
    required Future<void> Function() reconnect,
  }) async {
    if (isConnected() && getHub() != null) {
      return getHub();
    }

    try {
      final token = await AuthStorageService.getToken();
      if (token == null || token.isEmpty) {
        onError?.call('No token found, cannot connect to $hubPath', null);
        return null;
      }

      final baseUrl = AppConfig.baseUrl.replaceAll('/api', '');
      final hubUrl = '$baseUrl/$hubPath?access_token=$token';
      
      final httpOptions = HttpConnectionOptions(
        accessTokenFactory: () async => token,
      );
      
      final hub = HubConnectionBuilder()
          .withUrl(hubUrl, options: httpOptions)
          .build();

      // Đăng ký callback để nhận events
      hub.on(eventName, (arguments) {
        try {
          if (arguments != null && arguments.isNotEmpty) {
            final data = arguments[0];
            Map<String, dynamic> mapData;
            
            if (data is Map) {
              mapData = Map<String, dynamic>.from(data);
            } else if (data is String) {
              mapData = json.decode(data) as Map<String, dynamic>;
            } else {
              onError?.call('Unknown data format in $hubPath', data);
              return;
            }
            
            onReceived(mapData);
          }
        } catch (e) {
          onError?.call('Error parsing $hubPath event', e);
        }
      });

      // Xử lý connection events - tự động reconnect
      hub.onclose(({Exception? error}) {
        setConnected(false);
        if (error != null) {
          onError?.call('$hubPath disconnected', error);
        }
        Future.delayed(_reconnectDelay, () {
          if (!isConnected()) {
            reconnect();
          }
        });
      });

      await hub.start();
      setHub(hub);
      setConnected(true);
      
      return hub;
    } catch (e) {
      setConnected(false);
      onError?.call('Error connecting to $hubPath', e);
      // Retry sau delay
      Future.delayed(_retryDelay, () {
        if (!isConnected()) {
          reconnect();
        }
      });
      return null;
    }
  }

  /// Kết nối với NotificationHub để nhận thông báo real-time
  /// Hỗ trợ các loại: Reminder, SavedSearch, Message, approved, etc.
  Future<void> connectNotificationHub() async {
    _notificationHub = await _connectHub(
      hubPath: 'notificationHub',
      eventName: 'ReceiveNotification',
      onReceived: (data) => onNotificationReceived?.call(data),
      isConnected: () => _isNotificationHubConnected,
      setConnected: (value) => _isNotificationHubConnected = value,
      getHub: () => _notificationHub,
      setHub: (hub) => _notificationHub = hub,
      reconnect: connectNotificationHub,
    );
  }

  /// Kết nối với MessageHub để nhận tin nhắn real-time
  Future<void> connectMessageHub() async {
    _messageHub = await _connectHub(
      hubPath: 'messageHub',
      eventName: 'ReceiveMessage',
      onReceived: (data) => onMessageReceived?.call(data),
      isConnected: () => _isMessageHubConnected,
      setConnected: (value) => _isMessageHubConnected = value,
      getHub: () => _messageHub,
      setHub: (hub) => _messageHub = hub,
      reconnect: connectMessageHub,
    );
  }

  /// Kết nối tất cả hubs (gọi sau khi user đăng nhập)
  Future<void> connectAll() async {
    await connectNotificationHub();
    await connectMessageHub();
  }

  /// Ngắt kết nối tất cả hubs (gọi khi user đăng xuất)
  Future<void> disconnectAll() async {
    final futures = <Future>[];
    
    if (_notificationHub != null) {
      futures.add(_notificationHub!.stop().then((_) {
        _isNotificationHubConnected = false;
      }).catchError((e) {
        onError?.call('Error disconnecting notificationHub', e);
        _isNotificationHubConnected = false;
      }));
    }
    
    if (_messageHub != null) {
      futures.add(_messageHub!.stop().then((_) {
        _isMessageHubConnected = false;
      }).catchError((e) {
        onError?.call('Error disconnecting messageHub', e);
        _isMessageHubConnected = false;
      }));
    }
    
    await Future.wait(futures);
  }

  /// Kiểm tra trạng thái kết nối
  bool get isNotificationHubConnected => _isNotificationHubConnected;
  bool get isMessageHubConnected => _isMessageHubConnected;
}
