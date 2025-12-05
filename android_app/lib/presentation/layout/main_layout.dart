import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/favorite/favorites_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../widgets/navigation/custom_bottom_nav_bar.dart';

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

  void _openCreatePostScreen() {
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

