import 'package:flutter/material.dart';

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const ProfileMenuItem({required this.icon, required this.title, required this.onTap});
}

class ProfileMenuSection extends StatelessWidget {
  final List<ProfileMenuItem> items;
  const ProfileMenuSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((i) => ListTile(
                leading: Icon(i.icon),
                title: Text(i.title),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: i.onTap,
              ))
          .toList(),
    );
  }
}

