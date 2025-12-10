import 'package:flutter/material.dart';
import '../common/app_button.dart';

class EditCTA extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onLogout;
  const EditCTA({super.key, required this.onEdit, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Chỉnh sửa thông tin',
              isOutlined: true,
              onPressed: onEdit,
              icon: Icons.edit,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              text: 'Đăng xuất',
              isOutlined: true,
              backgroundColor: Colors.red,
              textColor: Colors.red,
              onPressed: onLogout,
              icon: Icons.logout,
            ),
          ),
        ],
      ),
    );
  }
}

