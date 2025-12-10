import 'package:flutter/material.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/post_repository.dart';
import '../../../core/repositories/favorite_repository.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/image_url_helper.dart' as image_helper;

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
            onPressed: () {
              // TODO: Điều hướng đến cài đặt
              // Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                      : null,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: avatarUrl == null
                      ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                            ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
                name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
                email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Yêu thích', _favoritesCount.toString()),
                _buildStatItem('Lịch hẹn', _appointmentsCount.toString()),
                _buildStatItem('Bài đăng', _postsCount.toString()),
              ],
            ),
            const SizedBox(height: 32),
            // Menu items
            _buildMenuItem(
              icon: Icons.edit,
              title: 'Chỉnh sửa thông tin',
              onTap: () {
                // TODO: Điều hướng đến edit profile
                // Navigator.pushNamed(context, '/edit-profile');
              },
            ),
            _buildMenuItem(
              icon: Icons.favorite,
              title: 'Yêu thích',
              onTap: () {
                // TODO: Điều hướng đến favorites
                // Navigator.pushNamed(context, '/favorites');
              },
            ),
            _buildMenuItem(
              icon: Icons.calendar_today,
              title: 'Lịch hẹn',
              onTap: () {
                // TODO: Điều hướng đến appointments
                // Navigator.pushNamed(context, '/appointments');
              },
            ),
            _buildMenuItem(
              icon: Icons.post_add,
              title: 'Quản lý bài đăng',
              onTap: () {
                // TODO: Điều hướng đến post management
                // Navigator.pushNamed(context, '/post-management');
              },
            ),
            _buildMenuItem(
              icon: Icons.notifications,
              title: 'Thông báo',
              onTap: () {
                // TODO: Điều hướng đến notifications
                // Navigator.pushNamed(context, '/notifications');
              },
            ),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Cài đặt',
              onTap: () {
                // TODO: Điều hướng đến settings
                // Navigator.pushNamed(context, '/settings');
              },
            ),
            const SizedBox(height: 16),
            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppButton(
                text: 'Đăng xuất',
                onPressed: _handleLogout,
                isOutlined: true,
                backgroundColor: Colors.red,
                textColor: Colors.red,
                icon: Icons.logout,
              ),
            ),
            const SizedBox(height: 32),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
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

