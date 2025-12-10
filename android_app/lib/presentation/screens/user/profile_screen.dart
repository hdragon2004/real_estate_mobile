import 'package:flutter/material.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/repositories/favorite_repository.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/models/post_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/image_url_helper.dart' as image_helper;
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/stat_pill_grid.dart';
import '../../widgets/profile/profile_about.dart';
import '../../widgets/profile/profile_listings.dart';
import '../../widgets/profile/profile_menu_section.dart';
import '../../widgets/profile/edit_cta.dart';

/// Màn hình Hồ sơ cá nhân
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepository = UserRepository();
  final PostRepository _postRepository = PostRepository();
  final FavoriteRepository _favoriteRepository = FavoriteRepository();

  bool _isLoading = true;
  User? _user;
  int _favoritesCount = 0;
  final int _appointmentsCount = 0; // TODO: Tạo API endpoint cho appointments
  int _postsCount = 0;
  List<PostModel> _userPosts = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) {
        // Không redirect về login, chỉ hiển thị trạng thái chưa đăng nhập
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _user = null;
        });
        return;
      }

      // Load profile
      final user = await _userRepository.getProfile();
      
      // Load posts count
      final posts = await _postRepository.getPostsByUser(userId);
      
      // Load favorites count
      final favorites = await _favoriteRepository.getFavoritesByUser(userId);

      if (!mounted) return;
      setState(() {
        _user = user;
        _userPosts = posts;
        _postsCount = posts.length;
        _favoritesCount = favorites.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ'),
          automaticallyImplyLeading: false,
        ),
        body: const LoadingIndicator(),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline,
                size: 64,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                'Yêu cầu đăng nhập',
                style: AppTextStyles.h6,
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn cần đăng nhập để xem hồ sơ cá nhân',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }

    final avatarUrl = _user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
        ? image_helper.ImageUrlHelper.resolveImageUrl(_user!.avatarUrl!)
        : null;
    final name = _user!.name;
    final email = _user!.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt',
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ProfileHeader(
                name: name,
                email: email,
                avatarUrl: avatarUrl,
                onEditTap: () {
                  Navigator.pushNamed(context, '/edit-profile');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: StatPillGrid(
                items: [
                  StatItem(label: 'Yêu thích', value: _favoritesCount.toString(), icon: Icons.favorite_outline),
                  StatItem(label: 'Lịch hẹn', value: _appointmentsCount.toString(), icon: Icons.calendar_today),
                  StatItem(label: 'Bài đăng', value: _postsCount.toString(), icon: Icons.post_add),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: ProfileAbout(
                title: 'Giới thiệu',
                description: _buildAboutText(),
                onReadMore: () => _showAboutSheet(),
              ),
            ),
            SliverToBoxAdapter(
              child: ProfileListings(
                posts: _userPosts,
                onSeeAll: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: ProfileMenuSection(
                items: [
                  ProfileMenuItem(icon: Icons.favorite, title: 'Yêu thích', onTap: () {}),
                  ProfileMenuItem(icon: Icons.calendar_today, title: 'Lịch hẹn', onTap: () {}),
                  ProfileMenuItem(icon: Icons.post_add, title: 'Quản lý bài đăng', onTap: () {}),
                  ProfileMenuItem(icon: Icons.notifications, title: 'Thông báo', onTap: () {}),
                  ProfileMenuItem(icon: Icons.settings, title: 'Cài đặt', onTap: () {}),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: EditCTA(
                  onEdit: () {
                    Navigator.pushNamed(context, '/edit-profile');
                  },
                  onLogout: _handleLogout,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildAboutText() {
    final phone = _user!.phone ?? '';
    final role = _user!.role;
    final created = _user!.create;
    final createdStr = created != null ? '${created.day}/${created.month}/${created.year}' : '';
    final parts = [
      'Tài khoản $role',
      if (phone.isNotEmpty) 'SĐT $phone',
      if (createdStr.isNotEmpty) 'Tạo ngày $createdStr',
    ];
    return parts.join(' • ');
  }

  void _showAboutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thông tin chi tiết', style: AppTextStyles.h6),
              const SizedBox(height: 12),
              _DetailRow(label: 'Họ và tên', value: _user!.name),
              _DetailRow(label: 'Email', value: _user!.email),
              if (_user!.phone != null) _DetailRow(label: 'Số điện thoại', value: _user!.phone!),
            ],
          ),
        );
      },
    );
  }

  

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất?',
      confirmText: 'Đăng xuất',
      cancelText: 'Hủy',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      // Xóa token và dữ liệu đăng nhập
      await ApiClient().clearAuthToken();
      await AuthStorageService.clearAll();
      
      if (!mounted) return;
      // Chuyển đến màn hình welcome và xóa tất cả route trước đó
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
