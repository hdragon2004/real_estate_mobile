import 'package:flutter/material.dart';

/// Màn hình Cài đặt thông báo
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _propertyNotifications = true;
  bool _appointmentNotifications = true;
  bool _messageNotifications = true;
  bool _systemNotifications = true;
  bool _emailNotifications = false;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
      ),
      body: ListView(
        children: [
          // General settings
          _buildSection(
            title: 'Cài đặt chung',
            children: [
              SwitchListTile(
                title: const Text('Thông báo đẩy'),
                subtitle: const Text('Nhận thông báo trên thiết bị'),
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                  // TODO: Lưu cài đặt
                },
              ),
              SwitchListTile(
                title: const Text('Thông báo email'),
                subtitle: const Text('Nhận thông báo qua email'),
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                  // TODO: Lưu cài đặt
                },
              ),
            ],
          ),
          const Divider(),
          // Notification types
          _buildSection(
            title: 'Loại thông báo',
            children: [
              SwitchListTile(
                title: const Text('Bất động sản'),
                subtitle: const Text('Thông báo về bất động sản mới, cập nhật'),
                value: _propertyNotifications,
                onChanged: (value) {
                  setState(() => _propertyNotifications = value);
                  // TODO: Lưu cài đặt
                },
              ),
              SwitchListTile(
                title: const Text('Lịch hẹn'),
                subtitle: const Text('Thông báo về lịch hẹn xem nhà'),
                value: _appointmentNotifications,
                onChanged: (value) {
                  setState(() => _appointmentNotifications = value);
                  // TODO: Lưu cài đặt
                },
              ),
              SwitchListTile(
                title: const Text('Tin nhắn'),
                subtitle: const Text('Thông báo khi có tin nhắn mới'),
                value: _messageNotifications,
                onChanged: (value) {
                  setState(() => _messageNotifications = value);
                  // TODO: Lưu cài đặt
                },
              ),
              SwitchListTile(
                title: const Text('Hệ thống'),
                subtitle: const Text('Thông báo từ hệ thống'),
                value: _systemNotifications,
                onChanged: (value) {
                  setState(() => _systemNotifications = value);
                  // TODO: Lưu cài đặt
                },
              ),
            ],
          ),
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
}

