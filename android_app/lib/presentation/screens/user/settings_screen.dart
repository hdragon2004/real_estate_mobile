import 'package:flutter/material.dart';
import '../../widgets/common/confirmation_dialog.dart';
// import 'device_info_demo_screen.dart'; // DeviceInfoDemoScreen không còn hoạt động
// import '../../../core/services/device_info_service.dart'; // DeviceInfoService đã bị xóa

/// Màn hình Cài đặt ứng dụng
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _selectedLanguage = 'Tiếng Việt';
  bool _locationServices = true;
  bool _analytics = true;
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    if (mounted) {
      setState(() {
        _appVersion = 'App Version 1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          // Appearance
          _buildSection(
            title: 'Giao diện',
            children: [
              SwitchListTile(
                title: const Text('Chế độ tối'),
                subtitle: const Text('Bật/tắt giao diện tối'),
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  // TODO: Áp dụng theme
                },
              ),
            ],
          ),
          const Divider(),
          // Language
          _buildSection(
            title: 'Ngôn ngữ',
            children: [
              ListTile(
                title: const Text('Ngôn ngữ'),
                subtitle: Text(_selectedLanguage),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showLanguageDialog();
                },
              ),
            ],
          ),
          const Divider(),
          // Privacy
          _buildSection(
            title: 'Quyền riêng tư',
            children: [
              SwitchListTile(
                title: const Text('Dịch vụ vị trí'),
                subtitle: const Text('Cho phép ứng dụng sử dụng vị trí'),
                value: _locationServices,
                onChanged: (value) {
                  setState(() => _locationServices = value);
                  // TODO: Cập nhật quyền
                },
              ),
              SwitchListTile(
                title: const Text('Phân tích dữ liệu'),
                subtitle: const Text('Cho phép thu thập dữ liệu phân tích'),
                value: _analytics,
                onChanged: (value) {
                  setState(() => _analytics = value);
                  // TODO: Cập nhật cài đặt
                },
              ),
            ],
          ),
          const Divider(),
          // About
          _buildSection(
            title: 'Về ứng dụng',
            children: [
              ListTile(
                title: const Text('Phiên bản'),
                subtitle: Text(_appVersion),
              ),
              ListTile(
                title: const Text('Thông tin thiết bị'),
                subtitle: const Text('Xem thông tin chi tiết về thiết bị'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // DeviceInfoDemoScreen đã bị xóa - comment lại
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const DeviceInfoDemoScreen(),
                  //   ),
                  // );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng này đã bị tạm thời vô hiệu hóa'),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Điều khoản sử dụng'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Mở điều khoản
                },
              ),
              ListTile(
                title: const Text('Chính sách bảo mật'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Mở chính sách
                },
              ),
              ListTile(
                title: const Text('Liên hệ hỗ trợ'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Mở liên hệ
                },
              ),
            ],
          ),
          const Divider(),
          // Danger zone
          _buildSection(
            title: 'Khu vực nguy hiểm',
            children: [
              ListTile(
                title: const Text(
                  'Xóa tài khoản',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _handleDeleteAccount,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tiếng Việt'),
              leading: Icon(
                _selectedLanguage == 'Tiếng Việt' 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                color: _selectedLanguage == 'Tiếng Việt' 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              onTap: () {
                setState(() {
                  _selectedLanguage = 'Tiếng Việt';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              leading: Icon(
                _selectedLanguage == 'English' 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                color: _selectedLanguage == 'English' 
                    ? Theme.of(context).primaryColor 
                    : null,
              ),
              onTap: () {
                setState(() {
                  _selectedLanguage = 'English';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Xóa tài khoản',
      message:
          'Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác.',
      confirmText: 'Xóa tài khoản',
      cancelText: 'Hủy',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      // TODO: Gọi API xóa tài khoản
      // Sau đó đăng xuất và điều hướng đến login
    }
  }
}

