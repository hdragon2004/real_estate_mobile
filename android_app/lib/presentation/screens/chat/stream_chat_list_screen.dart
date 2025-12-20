import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/services/stream_chat_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'stream_chat_screen.dart';

/// Stream Chat List Screen với pagination và real-time updates
class StreamChatListScreen extends StatefulWidget {
  const StreamChatListScreen({super.key});

  @override
  State<StreamChatListScreen> createState() => _StreamChatListScreenState();
}

class _StreamChatListScreenState extends State<StreamChatListScreen> {
  final StreamChatService _streamChatService = StreamChatService();
  StreamChannelListController? _channelListController;

  /// Lấy thông tin partner từ channel
  Map<String, dynamic> _getPartnerInfo(Channel channel) {
    final currentUserId = _streamChatService.currentUser?.id;
    if (currentUserId == null) return {};

    final membersMap =
        (channel.state?.members as Map?)?.cast<String, Member>() ??
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

  /// Navigate đến chat screen
  void _navigateToChat(Channel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamChatScreen(channel: channel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: FutureBuilder<int?>(
        future: AuthStorageService.getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final userId = snapshot.data;
          if (userId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text('Yêu cầu đăng nhập', style: AppTextStyles.h6),
                ],
              ),
            );
          }
          if (!_streamChatService.isConnected) {
            _streamChatService.connectUser();
          }

          final client = _streamChatService.client;
          if (client == null) {
            return const Center(child: CircularProgressIndicator());
          }

          _channelListController ??= StreamChannelListController(
            client: client,
            filter: Filter.in_('members', [userId.toString()]),
            channelStateSort: const [SortOption('last_message_at')],
          );

          return StreamChannelListView(
            controller: _channelListController!,
            onChannelTap: (channel) => _navigateToChat(channel),
            emptyBuilder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text('Chưa có tin nhắn', style: AppTextStyles.h6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
