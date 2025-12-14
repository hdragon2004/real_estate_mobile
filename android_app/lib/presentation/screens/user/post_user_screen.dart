import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/models/post_model.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/common/post_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../post/post_details_screen.dart';

/// Màn hình hiển thị các bài viết của user hiện tại
/// Phân biệt: Đã duyệt, Đợi duyệt, Bị từ chối
class PostUserScreen extends StatefulWidget {
  const PostUserScreen({super.key});

  @override
  State<PostUserScreen> createState() => _PostUserScreenState();
}

class _PostUserScreenState extends State<PostUserScreen>
    with SingleTickerProviderStateMixin {
  final PostRepository _postRepository = PostRepository();
  List<PostModel> _allPosts = [];
  bool _isLoading = true;
  String? _errorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Bạn cần đăng nhập để xem bài viết';
        });
        return;
      }

      final posts = await _postRepository.getPostsByUser(userId);
      
      // Debug: In ra để kiểm tra dữ liệu
      debugPrint('[PostUserScreen] Loaded ${posts.length} posts');
      for (var post in posts) {
        debugPrint('[PostUserScreen] Post ${post.id}: Status = "${post.status}"');
      }
      
      if (!mounted) return;
      setState(() {
        _allPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải bài viết: ${e.toString()}';
      });
    }
  }

  /// Lọc bài viết theo trạng thái
  /// Sử dụng Status: "Active" (đã duyệt), "Pending" (đợi duyệt), "Rejected" (bị từ chối)
  List<PostModel> _getPostsByStatus(String status) {
    switch (status) {
      case 'approved':
        // Lọc bài viết có Status = "Active" (đã duyệt)
        return _allPosts.where((post) {
          final postStatus = post.status.toLowerCase();
          return postStatus == 'active';
        }).toList();
      case 'pending':
        // Lọc bài viết có Status = "Pending" (đợi duyệt)
        return _allPosts.where((post) {
          final postStatus = post.status.toLowerCase();
          return postStatus == 'pending';
        }).toList();
      case 'rejected':
        // Lọc bài viết có Status = "Rejected" (bị từ chối)
        return _allPosts.where((post) {
          final postStatus = post.status.toLowerCase();
          return postStatus == 'rejected';
        }).toList();
      default:
        return [];
    }
  }

  /// Lấy màu badge theo trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Lấy text badge theo trạng thái
  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Đã duyệt';
      case 'pending':
        return 'Đợi duyệt';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return 'Không xác định';
    }
  }

  /// Lấy icon theo trạng thái
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return FontAwesomeIcons.circleCheck;
      case 'pending':
        return FontAwesomeIcons.clock;
      case 'rejected':
        return FontAwesomeIcons.circleXmark;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết của tôi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(FontAwesomeIcons.circleCheck),
              text: 'Đã duyệt',
            ),
            Tab(
              icon: Icon(FontAwesomeIcons.clock),
              text: 'Đợi duyệt',
            ),
            Tab(
              icon: Icon(FontAwesomeIcons.circleXmark),
              text: 'Bị từ chối',
            ),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: AppTextStyles.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsList('approved'),
                      _buildPostsList('pending'),
                      _buildPostsList('rejected'),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPostsList(String status) {
    final posts = _getPostsByStatus(status);

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài viết ${_getStatusText(status).toLowerCase()}',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailsScreen(propertyId: post.id.toString()),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(status),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              _getStatusIcon(status),
                              size: 14,
                              color: _getStatusColor(status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusText(status),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Post ID (optional)
                      Text(
                        '#${post.id}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Post Card Content
                  PostCard(
                    property: post,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailsScreen(propertyId: post.id.toString()),
                        ),
                      );
                    },
                  ),
                  // Additional Info
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đăng ngày: ${Formatters.formatDate(post.created)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      if (post.expiryDate != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.event_busy,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hết hạn: ${Formatters.formatDate(post.expiryDate!)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

