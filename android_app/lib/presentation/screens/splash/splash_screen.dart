import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/network/api_client.dart';

/// Màn hình Splash - Kiểm tra phiên đăng nhập và điều hướng
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Delay tối thiểu để hiển thị splash screen
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    // Đảm bảo token đã được load vào ApiClient (nếu có)
    // ApiClient.initialize() đã được gọi trong main(), nhưng đảm bảo chắc chắn
    final apiClient = ApiClient();
    
    // Kiểm tra xem có token đã lưu trong storage không
    final hasToken = await AuthStorageService.hasToken();
    
    if (hasToken) {
      // Có token trong storage, đảm bảo token đã được load vào ApiClient
      // Nếu chưa có trong ApiClient, load lại từ storage
      final token = await AuthStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        await apiClient.setAuthToken(token);
      }
      
      // Kiểm tra token còn hợp lệ không bằng cách gọi API getProfile
      try {
        final userService = UserService();
        final user = await userService.getProfile();
        
        // Token hợp lệ, user đã được đăng nhập tự động → vào thẳng home
        debugPrint('[SplashScreen] Token hợp lệ cho user: ${user.email}, vào thẳng home');
        
        if (!mounted) return;
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      } catch (e) {
        // Token không hợp lệ hoặc đã hết hạn
        debugPrint('[SplashScreen] Token không hợp lệ: $e');
        
        // Xóa token và dữ liệu đăng nhập
        await AuthStorageService.clearAll();
        await apiClient.clearAuthToken();
      }
    }
    
    // Không có token hoặc token không hợp lệ → chuyển đến welcome screen
    // Tại đây user có thể chọn đăng nhập hoặc tiếp tục không đăng nhập
    debugPrint('[SplashScreen] Không có token hoặc token không hợp lệ, chuyển đến màn hình chào mừng');
    if (!mounted) return;
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
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
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            // Background decorations
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x0DFFFFFF), // 5% white
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 1500.ms,
                  curve: Curves.easeOut,
                ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x08FFFFFF), // 3% white
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 1500.ms,
                  delay: 200.ms,
                  curve: Curves.easeOut,
                ),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Name
                  Text(
                    'Real Estate Hub',
                    style: AppTextStyles.h2.copyWith(
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        delay: 300.ms,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ),
                  
                  const SizedBox(height: 12),
                  
                  // Tagline
                  Text(
                    'Tìm kiếm ngôi nhà mơ ước',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xCCFFFFFF), // 80% white
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        delay: 500.ms,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xE6FFFFFF), // 90% white
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 400.ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        delay: 800.ms,
                        duration: 400.ms,
                      ),
                ],
              ),
            ),
            
            // Bottom branding
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Text(
                'Phiên bản 1.0.0',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0x80FFFFFF), // 50% white
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }
}

