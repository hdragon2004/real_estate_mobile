import 'package:flutter/material.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/confirmation_dialog.dart';

/// Màn hình Thông tin người chat
class ChatUserInfoScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? userPhone;
  final String? userEmail;

  const ChatUserInfoScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.userPhone,
    this.userEmail,
  });

  @override
  State<ChatUserInfoScreen> createState() => _ChatUserInfoScreenState();
}

class _ChatUserInfoScreenState extends State<ChatUserInfoScreen> {
  void _callUser() {
    if (widget.userPhone != null) {
      // TODO: Gọi điện
    }
  }

  void _emailUser() {
    if (widget.userEmail != null) {
      // TODO: Gửi email
    }
  }

  Future<void> _reportUser() async {
    if (!mounted) return;
    
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Báo cáo người dùng',
      message: 'Bạn có chắc chắn muốn báo cáo người dùng này?',
      confirmText: 'Báo cáo',
      cancelText: 'Hủy',
      confirmColor: Colors.red,
    );

    if (!mounted) return;
    
    if (confirmed == true) {
      // TODO: Gọi API báo cáo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi báo cáo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundImage: widget.userAvatar != null
                  ? NetworkImage(widget.userAvatar!)
                  : null,
              child: widget.userAvatar == null
                  ? Text(
                      widget.userName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 48),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            // Contact info
            if (widget.userPhone != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Số điện thoại'),
                subtitle: Text(widget.userPhone!),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: _callUser,
                ),
              ),
            if (widget.userEmail != null)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(widget.userEmail!),
                trailing: IconButton(
                  icon: const Icon(Icons.mail_outline),
                  onPressed: _emailUser,
                ),
              ),
            const SizedBox(height: 32),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  AppButton(
                    text: 'Báo cáo người dùng',
                    onPressed: _reportUser,
                    isOutlined: true,
                    backgroundColor: Colors.red,
                    textColor: Colors.red,
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

