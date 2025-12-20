import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../services/stream_chat_service.dart';

/// Wrapper widget cho Stream Chat provider
/// Tự động khởi tạo và cleanup Stream Chat client
class StreamChatWrapper extends StatefulWidget {
  final Widget child;

  const StreamChatWrapper({
    super.key,
    required this.child,
  });

  @override
  State<StreamChatWrapper> createState() => _StreamChatWrapperState();
}

class _StreamChatWrapperState extends State<StreamChatWrapper> {
  final _streamChatService = StreamChatService();
  StreamChatClient? _client;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeStreamChat();
  }

  Future<void> _initializeStreamChat() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      await _streamChatService.initialize();
      _client = _streamChatService.client;
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing Stream Chat: $e');
    } finally {
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    _streamChatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_client == null) {
      // Hiển thị loading hoặc child mà không có Stream Chat
      return widget.child;
    }

    return StreamChat(
      client: _client!,
      child: widget.child,
    );
  }
}