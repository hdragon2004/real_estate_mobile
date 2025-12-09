import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_storage_service.dart';

/// Màn hình Đăng ký tài khoản - Modern UI
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đồng ý với điều khoản sử dụng'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = AuthRepository();
      final authResponse = await authRepo.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        phone: _phoneController.text.trim(),
      );

      // Lưu token vào ApiClient và secure storage
      await ApiClient().setAuthToken(authResponse.token);
      // Lưu userId để sử dụng sau này
      await AuthStorageService.saveUserId(authResponse.user.id);

      if (!mounted) return;
      
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đăng ký thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Điều hướng đến Home
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      
      // Xử lý lỗi từ API
      String errorMessage = 'Đăng ký thất bại';
      if (e.toString().contains('Email đã tồn tại')) {
        errorMessage = 'Email này đã được sử dụng. Vui lòng chọn email khác.';
      } else if (e.toString().contains('Mật khẩu xác nhận không khớp')) {
        errorMessage = 'Mật khẩu xác nhận không khớp';
      } else {
        errorMessage = 'Đăng ký thất bại: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppShadows.medium,
                  ),
                  child: const Icon(
                    Iconsax.home_1,
                    size: 40,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Tạo tài khoản mới',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 8),
                
                Text(
                  'Điền thông tin để bắt đầu',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 32),
                
                // Name field
                _buildTextField(
                  controller: _nameController,
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên của bạn',
                  icon: Iconsax.user,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    if (value.length < 2) {
                      return 'Họ và tên phải có ít nhất 2 ký tự';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 20),
                
                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Nhập email của bạn',
                  icon: Iconsax.sms,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 20),
                
                // Phone field
                _buildTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hint: 'Nhập số điện thoại',
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (value.length < 10 || value.length > 11) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Số điện thoại chỉ được chứa số';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 20),
                
                // Password field
                _buildTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  icon: Iconsax.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 20),
                
                // Confirm password field
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  hint: 'Nhập lại mật khẩu',
                  icon: Iconsax.lock_1,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 16),
                
                // Terms checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() => _agreeToTerms = value ?? false);
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _agreeToTerms = !_agreeToTerms);
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'Tôi đồng ý với ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              TextSpan(
                                text: 'Điều khoản sử dụng',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' và ',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextSpan(
                                text: 'Chính sách bảo mật',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 500.ms),
                
                const SizedBox(height: 24),
                
                // Register button
                _buildPrimaryButton(
                  text: 'Đăng ký',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Đăng nhập',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 500.ms),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return _AnimatedPrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}

/// Animated Primary Button với scale + haptic feedback
class _AnimatedPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const _AnimatedPrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<_AnimatedPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (!widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: widget.isLoading ? 0.7 : 1.0,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadows.small,
                ),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.text,
                          style: AppTextStyles.buttonLarge,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

