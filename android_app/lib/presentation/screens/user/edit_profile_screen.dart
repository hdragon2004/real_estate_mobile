import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../../core/services/post_service.dart';
import '../../widgets/profile/avatar_picker.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/choose_photo.dart';

/// Màn hình Chỉnh sửa thông tin cá nhân
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String? _avatarUrl;
  File? _selectedImage;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    // TODO: Load thông tin hiện tại
    _nameController.text = 'Nguyễn Văn A';
    _emailController.text = 'nguyenvana@example.com';
    _phoneController.text = '0123456789';
    _addressController.text = '123 Đường ABC, Quận 1, TP.HCM';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showImageSourceDialog(context);
    if (source == null) return;

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
    
    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
        // TODO: Upload ảnh lên server và lấy URL
        // _avatarUrl = await uploadImage(imageFile);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cập nhật hồ sơ',
      message: 'Xác nhận lưu thay đổi?',
      confirmText: 'Lưu',
      cancelText: 'Hủy',
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);

    // TODO: Gọi API cập nhật profile
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              AvatarPicker(
                imageProvider: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null),
                initials: _nameController.text.isNotEmpty
                    ? _nameController.text[0].toUpperCase()
                    : 'U',
                onTap: _pickImage,
              ),
              const SizedBox(height: 32),
              // Name
              AppTextField(
                label: 'Họ và tên',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                enabled: false, // Email thường không cho sửa
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone
              AppTextField(
                label: 'Số điện thoại',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (value.length < 10) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Address
              AppTextField(
                label: 'Địa chỉ',
                controller: _addressController,
                prefixIcon: const Icon(Icons.location_on_outlined),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              // Save button
              AppButton(
                text: 'Lưu thay đổi',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
