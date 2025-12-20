import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/services/stream_chat_service.dart';

/// Stream Chat Screen với message pagination và real-time updates
class StreamChatScreen extends StatefulWidget {
  final Channel channel;

  const StreamChatScreen({super.key, required this.channel});

  @override
  State<StreamChatScreen> createState() => _StreamChatScreenState();
}

class _StreamChatScreenState extends State<StreamChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final StreamChatService _streamChatService = StreamChatService();
  bool _partnerOnline = false;

  @override
  void initState() {
    super.initState();
    _setupOnlineStatusListener();
    _markChannelAsRead();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Setup online status listener
  void _setupOnlineStatusListener() {
    final partnerInfo = _getPartnerInfo();
    if (partnerInfo['id'] != null) {
      _streamChatService
          .getUserOnlineStatusStream(widget.channel, partnerInfo['id'])
          .listen((isOnline) {
            if (mounted) {
              setState(() {
                _partnerOnline = isOnline;
              });
            }
          });
    }
  }

  /// Đánh dấu channel đã đọc
  Future<void> _markChannelAsRead() async {
    try {
      await _streamChatService.markChannelAsRead(widget.channel);
    } catch (e) {
      debugPrint('Error marking channel as read: $e');
    }
  }

  /// Lấy thông tin partner
  Map<String, dynamic> _getPartnerInfo() {
    final currentUserId = _streamChatService.currentUser?.id;
    if (currentUserId == null) return {};

    final membersMap =
        (widget.channel.state?.members as Map?)?.cast<String, Member>() ??
        <String, Member>{};
    final members = membersMap.values.toList();
    if (members.isEmpty) return {};
    final partner = members.firstWhere(
      (member) => member.userId != currentUserId,
      orElse: () => members.first,
    );

    return {
      'name': partner.user?.name ?? 'Người dùng',
      'avatar': partner.user?.image,
      'isOnline': partner.user?.online ?? false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final partnerInfo = _getPartnerInfo();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: partnerInfo['avatar'] != null
                  ? NetworkImage(partnerInfo['avatar'])
                  : null,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: partnerInfo['avatar'] == null
                  ? Text(
                      partnerInfo['name']?[0] ?? 'U',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partnerInfo['name'] ?? 'Người dùng',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_partnerOnline)
                    Text(
                      'Đang hoạt động',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    )
                  else
                    Text(
                      'Không hoạt động',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Show channel info
            },
          ),
        ],
      ),
      body: StreamChannel(
        channel: widget.channel,
        child: Column(
          children: [
            const Expanded(child: StreamMessageListView()),
            const StreamMessageInput(),
          ],
        ),
      ),
    );
  }

  /// Format message time
  String _formatMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
