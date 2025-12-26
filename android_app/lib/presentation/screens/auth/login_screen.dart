import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_storage_service.dart';

/// Màn hình Đăng nhập - Dark theme với background image
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final authResponse = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Lưu token vào ApiClient và secure storage
      await ApiClient().setAuthToken(authResponse.token);
      // Lưu userId để sử dụng sau này
      await AuthStorageService.saveUserId(authResponse.user.id);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thất bại: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    // TODO: Implement Google login
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A4A4F), // Medium blue-green - vừa đủ sáng, không quá chói
              Color(0xFF3D5A5F),
              Color(0xFF2A4A4F),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background1.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            // Dark overlay - lớp mỏng đen để làm tối ảnh, không làm mờ
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Content
            SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Title
                Text(
                        'Login',
                  textAlign: TextAlign.center,
                        style: AppTextStyles.h1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 48),
                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Nhập email của bạn',
                  keyboardType: TextInputType.emailAddress,
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
                const SizedBox(height: 20),
                // Password field
                _buildTextField(
                  controller: _passwordController,
                        label: 'Password',
                  hint: 'Nhập mật khẩu',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                          icon: FaIcon(
                            _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                            color: Colors.grey.shade300,
                            size: 20,
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
                      ),
                      const SizedBox(height: 16),
                      // Remember me và Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value);
                                },
                                activeThumbColor: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Remember me',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                    onPressed: _navigateToForgotPassword,
                    child: Text(
                              'Forgot Password?',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                        ],
                      ),
                      const SizedBox(height: 32),
                // Login button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Login',
                                style: AppTextStyles.buttonLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 32),
                // Divider
                Row(
                  children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade600,
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                              'or login with',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey.shade400,
                              ),
                      ),
                    ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade600,
                            ),
                          ),
                  ],
                      ),
                const SizedBox(height: 24),
                // Social login buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        icon: 'G',
                        onPressed: _handleGoogleLogin,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialButton(
                              icon: FontAwesomeIcons.twitter,
                              onPressed: () {
                                // TODO: Implement Twitter login
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSocialButton(
                              icon: FontAwesomeIcons.facebook,
                              onPressed: () {
                                // TODO: Implement Facebook login
                              },
                      ),
                    ),
                  ],
                      ),
                const SizedBox(height: 32),
                      // Signup link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                            "Bạn chưa có tài khoản? ",
                      style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey.shade300,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToRegister,
                      child: Text(
                              'Đăng ký',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey.shade800,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey.shade500,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required dynamic icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
              child: Container(
        width: 60,
        height: 60,
                decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
          child: icon is String
              ? Text(
                  icon,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : FaIcon(
                  icon as IconData,
                  color: Colors.white,
                  size: 24,
                    ),
                  ),
      ),
    );
  }
}
