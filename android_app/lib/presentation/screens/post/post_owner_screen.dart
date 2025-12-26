import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/post_model.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/post_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../post/post_details_screen.dart';
import '../chat/chat_screen.dart';

/// Màn hình hiển thị thông tin chủ bài đăng và các bài đăng của họ
class PostOwnerScreen extends StatefulWidget {
  final int userId;
  final String? userName;
  final String? userAvatar;
  final String? userEmail;
  final String? userPhone;
  final String? userRole;
  final int? postId; // PostId để chat về bài đăng cụ thể (có thể null)

  const PostOwnerScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
    this.userEmail,
    this.userPhone,
    this.userRole,
    this.postId,
  });

  @override
  State<PostOwnerScreen> createState() => _PostOwnerScreenState();
}

class _PostOwnerScreenState extends State<PostOwnerScreen> {
  final PostService _postService = PostService();
  List<PostModel> _userPosts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await _postService.getPostsByUser(widget.userId);
      
      if (!mounted) return;
      setState(() {
        _userPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải bài đăng: ${e.toString()}';
      });
    }
  }

  Future<void> _launchMail(String? email) async {
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email không có sẵn'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở ứng dụng email'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số điện thoại không có sẵn'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở ứng dụng gọi điện'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _navigateToChat() async {
    final currentUserId = await AuthStorageService.getUserId();
    if (currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần đăng nhập để nhắn tin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (currentUserId == widget.userId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không thể nhắn tin cho chính mình'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: widget.postId != null 
              ? '${widget.userId}_${widget.postId}'
              : 'user_${widget.userId}',
          otherUserId: widget.userId,
          postId: widget.postId,
          userName: widget.userName,
          userAvatar: widget.userAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông tin người đăng'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserPosts,
        child: CustomScrollView(
          slivers: [
            // Thông tin user
            SliverToBoxAdapter(
              child: _buildUserInfo(),
            ),
            // Các button hành động
            SliverToBoxAdapter(
              child: _buildActionButtons(),
            ),
            // Danh sách bài đăng
            SliverToBoxAdapter(
              child: _buildPostsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          UserAvatarWithFallback(
            avatarUrl: widget.userAvatar,
            name: widget.userName ?? 'Người dùng',
            radius: 40,
            fontSize: 24,
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName ?? 'Người dùng',
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(2),
                Text(
                  widget.userRole ?? 'Người dùng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.userEmail != null && widget.userEmail!.isNotEmpty) ...[
                  const Gap(6),
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.envelope,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          widget.userEmail!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.userPhone != null && widget.userPhone!.isNotEmpty) ...[
                  const Gap(2),
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.phone,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const Gap(8),
                      Text(
                        widget.userPhone!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: FontAwesomeIcons.envelope,
              label: 'Gửi mail',
              color: AppColors.primary,
              onPressed: () => _launchMail(widget.userEmail),
            ),
          ),
          const Gap(12),
          Expanded(
            child: _ActionButton(
              icon: FontAwesomeIcons.phone,
              label: 'Gọi điện',
              color: AppColors.success,
              onPressed: () => _launchPhone(widget.userPhone),
            ),
          ),
          const Gap(12),
          Expanded(
            child: _ActionButton(
              icon: FontAwesomeIcons.message,
              label: 'Nhắn tin',
              color: AppColors.info,
              onPressed: _navigateToChat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Các bài đăng của ${widget.userName ?? "người dùng"}',
            style: AppTextStyles.h5,
          ),
          const Gap(8),
          if (_isLoading)
            const LoadingIndicator()
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(16),
                    ElevatedButton(
                      onPressed: _loadUserPosts,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          else if (_userPosts.isEmpty)
            const EmptyState(
              icon: FontAwesomeIcons.house,
              title: 'Chưa có bài đăng',
              message: 'Người dùng này chưa đăng bài nào',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userPosts.length,
              itemBuilder: (context, index) {
                final post = _userPosts[index];
                return PostCard(
                  property: post,
                  margin: const EdgeInsets.only(bottom: 8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsScreen(
                          propertyId: post.id.toString(),
                          initialProperty: post,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: FaIcon(icon, size: 16, color: color),
      label: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

