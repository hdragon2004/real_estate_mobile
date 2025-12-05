import 'package:flutter/material.dart';

/// Màn hình đăng tin bất động sản
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tin'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Xử lý đăng tin
            },
            child: const Text('Đăng'),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Màn hình đăng tin\n(Sẽ được phát triển)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
