import 'package:flutter/material.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_storage_service.dart';

/// Màn hình Hồ sơ cá nhân
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: Load từ API/Provider
  final String _name = 'Nguyễn Văn A';
  final String _email = 'nguyenvana@example.com';
  String? _avatarUrl;
  final int _favoritesCount = 0;
  final int _appointmentsCount = 0;
  final int _postsCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null
                      ? Text(
                          _name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 48),
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
              _name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _email,
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
      // Chuyển đến màn hình đăng nhập và xóa tất cả route trước đó
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}

