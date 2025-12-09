import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/favorite/favorites_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../widgets/navigation/custom_bottom_nav_bar.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Layout chính với Custom Bottom Navigation Bar
/// Thiết kế: 5 tabs - Trang chủ, Yêu thích, Đăng tin (FAB), Tin nhắn, Tài khoản
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isScrolling = false;
  
  // Scroll controller để theo dõi trạng thái scroll
  final ScrollController _scrollController = ScrollController();

  // 4 màn hình chính (không bao gồm Đăng tin - sẽ mở dạng modal)
  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isScrolling = _scrollController.offset > 50;
    if (isScrolling != _isScrolling) {
      setState(() {
        _isScrolling = isScrolling;
      });
    }
  }

  Future<void> _openCreatePostScreen() async {
    // Kiểm tra user đã đăng nhập chưa
    final userRepository = UserRepository();
    try {
      await userRepository.getProfile();
      // Nếu đã đăng nhập, mở màn hình đăng tin
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const CreatePostScreen();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      // Nếu chưa đăng nhập, hiển thị dialog yêu cầu đăng nhập
      if (!mounted) return;
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Yêu cầu đăng nhập',
            style: AppTextStyles.h6,
          ),
          content: Text(
            'Bạn cần đăng nhập để đăng tin. Vui lòng đăng nhập để tiếp tục.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Hủy',
                style: AppTextStyles.labelLarge,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Đăng nhập',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );

      // Nếu user chọn đăng nhập, chuyển đến màn hình đăng nhập
      if (shouldLogin == true && mounted) {
        Navigator.pushNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        isScrolling: _isScrolling,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onPostTap: _openCreatePostScreen,
      ),
    );
  }
}

