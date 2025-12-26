import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/favorite/favorites_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../widgets/navigation/custom_bottom_nav_bar.dart';
import '../widgets/navigation/app_drawer.dart';
import '../../core/services/message_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/auth_storage_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/models/notification_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/error/error_handler.dart';
import '../widgets/common/notification_banner.dart';
import '../screens/post/post_details_screen.dart';
import '../screens/notification/notification_details_screen.dart';

/// Layout chính với Custom Bottom Navigation Bar
/// Thiết kế: 4 tabs - Trang chủ, Tìm kiếm, Tin nhắn, Yêu thích + Nút đăng tin (FAB)
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isScrolling = false;
  bool _hasUnreadMessages = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Scroll controller để theo dõi trạng thái scroll
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  final NotificationService _notificationService = NotificationService();
  
  // Quản lý banner thông báo
  NotificationModel? _currentNotification;

  // Key để truy cập SearchScreen state
  final GlobalKey<SearchScreenState> _searchScreenKey =
      GlobalKey<SearchScreenState>();

  // 5 tabs: Trang chủ, Tìm kiếm, Tin nhắn, Yêu thích + nút đăng tin (FAB mở modal)
  List<Widget> get _screens => [
    HomeScreen(
      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      onSearchTap: _switchToSearchTab,
    ),
    SearchScreen(key: _searchScreenKey),
    const ChatListScreen(),
    const FavoritesScreen(),
  ];

  // Method để chuyển sang tab Search và có thể truyền filters
  void _switchToSearchTab({Map<String, dynamic>? filters}) {
    setState(() {
      _currentIndex = 1;
    });
    // Nếu có filters, truyền vào SearchScreen
    if (filters != null && _searchScreenKey.currentState != null) {
      _searchScreenKey.currentState!.applyFilters(filters);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkUnreadMessages();
    _initializeNotifications();
  }

  /// Khởi tạo NotificationService và kết nối SignalR
  Future<void> _initializeNotifications() async {
    try {
      // Khởi tạo NotificationService (sẽ tự động kết nối SignalR nếu user đã đăng nhập)
      await _notificationService.initialize();

      // Lắng nghe thông báo real-time
      _notificationService.notificationStream.listen((notification) {
        _showNotificationBanner(notification);
      });

      // Lắng nghe tin nhắn real-time
      _notificationService.messageStream.listen((messageData) {
        // Có thể cập nhật badge tin nhắn ở đây
        _checkUnreadMessages();
      });

      // Lắng nghe lỗi từ NotificationService và hiển thị cho người dùng
      _notificationService.errorStream.listen((error) {
        if (mounted) {
          ErrorHandler.showError(context, error);
        }
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  /// Hiển thị thông báo dưới dạng Banner ở phía trên
  void _showNotificationBanner(NotificationModel notification) {
    if (!mounted) return;
    
    setState(() {
      _currentNotification = notification;
    });
  }

  /// Xử lý khi user nhấn "Xem" trên banner
  void _handleViewNotification(NotificationModel notification) {
    if (notification.postId != null) {
      // Navigate đến post details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailsScreen(
            propertyId: notification.postId.toString(),
          ),
        ),
      );
    } else if (notification.appointmentId != null) {
      // Navigate đến appointment details hoặc notification details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationDetailsScreen(
            notification: notification,
          ),
        ),
      );
    } else {
      // Navigate đến notification details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationDetailsScreen(
            notification: notification,
          ),
        ),
      );
    }
  }

  /// Xử lý khi banner bị dismiss
  void _handleDismissBanner() {
    if (mounted) {
      setState(() {
        _currentNotification = null;
      });
    }
  }

  Future<void> _checkUnreadMessages() async {
    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) return;

      final conversations = await _messageService.getConversations(userId);
      final hasUnread = conversations.any(
        (conv) => (conv['unreadCount'] as int? ?? 0) > 0,
      );

      if (mounted) {
        setState(() {
          _hasUnreadMessages = hasUnread;
        });
      }
    } catch (e) {
      // Ignore errors, keep default false
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Ngắt kết nối SignalR khi dispose (nhưng không dispose NotificationService vì nó là singleton)
    // NotificationService sẽ tự quản lý lifecycle
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
    final userService = UserService();
    try {
      await userService.getProfile();
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
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
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
          title: Text('Yêu cầu đăng nhập', style: AppTextStyles.h6),
          content: Text(
            'Bạn cần đăng nhập để đăng tin. Vui lòng đăng nhập để tiếp tục.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy', style: AppTextStyles.labelLarge),
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
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refresh unread messages khi chuyển tab
          if (index == 2) {
            _checkUnreadMessages();
          }
        },
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          // Banner thông báo ở phía trên
          if (_currentNotification != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: NotificationBanner(
                  notification: _currentNotification!,
                  onView: () => _handleViewNotification(_currentNotification!),
                  onDismiss: _handleDismissBanner,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        isScrolling: _isScrolling,
        hasUnreadMessages: _hasUnreadMessages,
        onTap: (index) async {
          // Kiểm tra đăng nhập cho các tab cần thiết
          if (index == 2 || index == 3) {
            // Chat, Favorites (Search không cần đăng nhập)
            final userId = await AuthStorageService.getUserId();
            if (userId == null) {
              // Hiển thị dialog yêu cầu đăng nhập
              if (!mounted || !context.mounted) {
                return;
              }
              final shouldLogin = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text('Yêu cầu đăng nhập', style: AppTextStyles.h6),
                  content: Text(
                    'Bạn cần đăng nhập để sử dụng tính năng này.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Hủy', style: AppTextStyles.labelLarge),
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
              if (!mounted || !context.mounted) {
                return;
              }

              if (shouldLogin == true) {
                Navigator.pushNamed(context, '/login');
              }
              return;
            }
          }

          setState(() {
            _currentIndex = index;
          });
          // Refresh unread messages khi chuyển tab
          if (index == 2) {
            _checkUnreadMessages();
          }
        },
        onPostTap: _openCreatePostScreen,
      ),
    );
  }
}
