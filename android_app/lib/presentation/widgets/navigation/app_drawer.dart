import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../screens/user/profile_screen.dart';
import '../../screens/appointment/appointments_list_screen.dart';
import '../common/user_avatar.dart';

/// App Drawer - Sidebar Navigation
class AppDrawer extends StatefulWidget {
  final Function(int)? onNavigate;
  final int? currentIndex;

  const AppDrawer({
    super.key,
    this.onNavigate,
    this.currentIndex,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _userService.getProfile();
      if (mounted) {
        setState(() {
          _userInfo = {
            'name': user.name,
            'email': user.email,
            // Backend đã trả về avatar mặc định nếu user không có avatar
            'avatarUrl': user.avatarUrl ?? '/uploads/avatars/avatar.jpg',
          };
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Đăng xuất',
          style: AppTextStyles.h6,
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: AppTextStyles.labelLarge,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Đăng xuất',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Xóa token và user data
      await AuthStorageService.clearAll();
      await ApiClient().clearAuthToken();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/welcome',
        (route) => false,
      );
    }
  }

  void _navigateTo(int index) {
    Navigator.pop(context); // Đóng drawer
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header với user info
          _buildHeader(),
          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: FontAwesomeIcons.house,
                  activeIcon: FontAwesomeIcons.solidHouse,
                  title: 'Trang chủ',
                  onTap: () => _navigateTo(0),
                  isSelected: widget.currentIndex == 0,
                ),
                _buildMenuItem(
                  icon: FontAwesomeIcons.magnifyingGlass,
                  title: 'Tìm kiếm',
                  onTap: () => _navigateTo(1),
                  isSelected: widget.currentIndex == 1,
                ),
                _buildMenuItem(
                  icon: FontAwesomeIcons.message,
                  activeIcon: FontAwesomeIcons.solidMessage,
                  title: 'Tin nhắn',
                  onTap: () => _navigateTo(2),
                  isSelected: widget.currentIndex == 2,
                ),
                _buildMenuItem(
                  icon: FontAwesomeIcons.heart,
                  activeIcon: FontAwesomeIcons.solidHeart,
                  title: 'Yêu thích',
                  onTap: () => _navigateTo(3),
                  isSelected: widget.currentIndex == 3,
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: FontAwesomeIcons.user,
                  activeIcon: FontAwesomeIcons.solidUser,
                  title: 'Tài khoản',
                  onTap: () {
                    Navigator.pop(context); // Đóng drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: FontAwesomeIcons.calendarDays,
                  activeIcon: FontAwesomeIcons.calendarCheck,
                  title: 'Lịch hẹn',
                  onTap: () {
                    Navigator.pop(context); // Đóng drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppointmentsListScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: FontAwesomeIcons.gear,
                  title: 'Cài đặt',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings screen
                  },
                ),
                _buildMenuItem(
                  icon: FontAwesomeIcons.fileLines,
                  title: 'Chính sách',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to policies screen
                  },
                ),
              ],
            ),
          ),
          // Logout button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120,
        maxHeight: 170,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/image1.jpg', // Thay đổi đường dẫn theo ảnh của bạn
            fit: BoxFit.cover,
            alignment: Alignment.center, // Căn giữa để crop đẹp hơn
            errorBuilder: (context, error, stackTrace) {
              // Fallback về gradient nếu không tìm thấy ảnh
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                ),
              );
            },
          ),
          // Overlay tối để text dễ đọc hơn và làm mờ ảnh
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  UserAvatarWithFallback(
                    avatarUrl: _userInfo?['avatarUrl']?.toString(),
                    name: _userInfo?['name']?.toString() ?? 'User',
                    radius: 26,
                  backgroundColor: Colors.white,
                    fontSize: 18,
                ),
                const SizedBox(height: 4),
                // Name
                Text(
                  _userInfo?['name'] ?? 'Người dùng',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Email
                Text(
                  _userInfo?['email'] ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    IconData? activeIcon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: FaIcon(
        isSelected && activeIcon != null ? activeIcon : icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: const FaIcon(
          FontAwesomeIcons.rightFromBracket,
          color: AppColors.error,
          size: 20,
        ),
        title: Text(
          'Đăng xuất',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: _handleLogout,
      ),
    );
  }
}

