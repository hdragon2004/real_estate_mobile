import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/post_service.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/choose_photo.dart';
import 'post_user_screen.dart';

/// Màn hình Thông tin tài khoản
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final PostService _postService = PostService();

  bool _isUploadingAvatar = false;
  File? _tempAvatarFile; // Ảnh tạm thời khi chọn xong, chưa upload
  User? _user;
  bool _isEmailVisible = false;
  String _appVersion = 'Đang tải...';
  final String _selectedLanguage = 'Tiếng Việt';
  final String _selectedTheme = 'Theo hệ thống';
  final String _securityMethod = 'Biometric & Mật khẩu';
  bool _hasCheckedAuth = false; // Đánh dấu đã kiểm tra auth chưa
  bool _isNotLoggedIn = false; // Đánh dấu user chưa đăng nhập

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Load trong background, không hiển thị loading
    _loadAppVersion();
  }

  Future<void> _loadProfileData() async {
    // Load trong background, không set _isLoading = true
    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _hasCheckedAuth = true;
          _isNotLoggedIn = true; // Đánh dấu là chưa đăng nhập
          _user = null;
        });
        return;
      }

      // Có userId, đang load profile
      setState(() {
        _hasCheckedAuth = true;
        _isNotLoggedIn = false;
      });

      final user = await _userService.getProfile();

      if (!mounted) return;
      setState(() {
        _user = user;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasCheckedAuth = true;
      });
      // Chỉ hiển thị error nếu chưa có user data
      if (_user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadAppVersion() async {
    // DeviceInfoService đã bị xóa, comment lại
    // final appInfo = await DeviceInfoService.getAppInfo();
    // if (appInfo != null && mounted) {
    //   setState(() {
    //     _appVersion = 'Phiên bản ${appInfo.version}';
    //   });
    // }
    if (mounted) {
      setState(() {
        _appVersion = 'Phiên bản 1.0.0'; // Hardcode version
      });
    }
  }

  /// Reload chỉ user data (không hiển thị loading toàn màn hình)
  Future<void> _reloadUserData() async {
    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _user = null;
        });
        return;
      }

      final user = await _userService.getProfile();

      if (!mounted) return;
      setState(() {
        _user = user;
      });
    } catch (e) {
      // Không hiển thị error khi reload, chỉ log
      debugPrint('Error reloading user data: $e');
    }
  }

  Future<void> _updateAvatar() async {
    // Hiển thị bottom sheet cho phép chọn camera hoặc thư viện
    final source = await showImageSourceDialog(context);
    if (source == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      if (!mounted) {
        setState(() => _isUploadingAvatar = false);
        return;
      }
      
      File? imageFile;
      
      if (source == 'camera') {
        imageFile = await _postService.takePicture(context);
      } else if (source == 'gallery') {
        final images = await _postService.pickMultipleImagesFromGallery(
          context,
          maxImages: 1,
        );
        if (images.isNotEmpty) {
          imageFile = images.first;
        }
      }
      
      if (!mounted) {
        setState(() => _isUploadingAvatar = false);
        return;
      }

      if (imageFile == null || !mounted) {
        setState(() => _isUploadingAvatar = false);
        return;
      }

      // Hiển thị ảnh preview ngay lập tức
      setState(() {
        _tempAvatarFile = imageFile;
      });

      // Upload avatar
      await _userService.uploadAvatar(imageFile.path);
      
      // Reload chỉ user data để lấy avatar mới (không hiển thị loading toàn màn hình)
      await _reloadUserData();
      
      // Xóa ảnh tạm thời sau khi upload thành công
      if (mounted) {
        setState(() {
          _tempAvatarFile = null;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật ảnh đại diện thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật ảnh đại diện: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  // ignore: unused_element
  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    final maskedUsername = username.length > 2
        ? '${username.substring(0, 2)}${'*' * (username.length - 2)}'
        : '***';
    final domainParts = domain.split('.');
    final maskedDomain = domainParts.length > 1
        ? '${'*' * domainParts[0].length}.${domainParts.sublist(1).join('.')}'
        : '***';
    return '$maskedUsername@$maskedDomain';
  }

  void _toggleEmailVisibility() {
    setState(() {
      _isEmailVisible = !_isEmailVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ hiển thị "Yêu cầu đăng nhập" khi đã kiểm tra và chắc chắn chưa đăng nhập
    if (_hasCheckedAuth && _isNotLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Thông tin tài khoản'),
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

    // Nếu chưa có user nhưng đã có userId (đang load), hiển thị UI với placeholder
    // Hoặc nếu đã có user, hiển thị UI bình thường
    final name = _user?.name ?? 'Đang tải...';
    final email = _user?.email ?? 'Đang tải...';
    final roleDisplay = _user?.role ?? 'Người dùng';
    final displayEmail = _isEmailVisible ? email : (email == 'Đang tải...' ? 'Đang tải...' : _maskEmail(email));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Quay về trang chủ (index 0)
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
        ),
        title: Text(
          'Thông tin tài khoản',
          style: AppTextStyles.h6,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.medium,
              ),
              child: Column(
                children: [
                  // Phần trên: Avatar bên trái, Tên và Role bên phải
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar với camera icon (bên trái)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _tempAvatarFile != null
                              ? CircleAvatar(
                                  radius: 40,
                                  backgroundImage: FileImage(_tempAvatarFile!),
                                )
                              : UserAvatarWithFallback(
                                  avatarUrl: _user?.avatarUrl,
                                  name: name,
                                  radius: 40,
                                  fontSize: 32,
                                ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: GestureDetector(
                              onTap: _isUploadingAvatar ? null : _updateAvatar,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 2,
                                  ),
                                  boxShadow: AppShadows.small,
                                ),
                                child: _isUploadingAvatar
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Tên, Role và Button Chỉnh sửa (bên phải)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username và Button Chỉnh sửa (icon bút) cùng hàng
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: AppTextStyles.h5,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    // TODO: Navigate to edit profile screen
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  tooltip: 'Chỉnh sửa',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Role Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                roleDisplay,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Thông tin đăng ký (nằm ở dưới, ngoài phần avatar)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Thông tin đăng ký',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayEmail,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _toggleEmailVisibility,
                          child: Icon(
                            _isEmailVisible ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Settings List (không có khung, chỉ có divider)
            Column(
              children: [
                _buildSettingItem(
                  icon: FontAwesomeIcons.newspaper,
                  title: 'Bài viết',
                  value: 'Quản lý bài đăng',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostUserScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildSettingItem(
                  icon: FontAwesomeIcons.globe,
                  title: 'Ngôn ngữ',
                  value: _selectedLanguage,
                  onTap: () {
                    // TODO: Navigate to language settings
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildSettingItem(
                  icon: FontAwesomeIcons.moon,
                  title: 'Giao diện',
                  value: _selectedTheme,
                  onTap: () {
                    // TODO: Navigate to theme settings
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildSettingItem(
                  icon: FontAwesomeIcons.shield,
                  title: 'Bảo mật',
                  value: _securityMethod,
                  onTap: () {
                    // TODO: Navigate to security settings
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildSettingItem(
                  icon: FontAwesomeIcons.circleInfo,
                  title: 'Thông tin ứng dụng',
                  value: _appVersion,
                  onTap: () {
                    // TODO: Navigate to app info screen
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      color: AppColors.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.labelLarge,
        ),
        subtitle: Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
