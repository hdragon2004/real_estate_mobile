import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/appointment/appointment_card.dart';
import '../chat/chat_screen.dart';
import '../post/post_details_screen.dart';

/// Màn hình danh sách lịch hẹn của user
/// Phân biệt: Đã chấp nhận, Chờ xác nhận, Bị từ chối
class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _allAppointments = [];
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;
  // Cache post ownership: Map<postId, postOwnerId>
  final Map<int, int> _postOwnershipCache = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUserId();
    _loadAppointments();
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await AuthStorageService.getUserId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load current user ID nếu chưa có
      _currentUserId ??= await AuthStorageService.getUserId();
      
      // Load cả 2 loại appointments:
      // 1. Appointments mà user đã tạo (user đặt lịch hẹn)
      // 2. Appointments cho các bài post của user (chủ bài post)
      final userCreatedAppointments = await _appointmentService.getUserAppointments();
      
      // Load appointments cho bài post của user (có thể fail nếu endpoint chưa được deploy)
      List<Map<String, dynamic>> postOwnerAppointments = [];
      try {
        postOwnerAppointments = await _appointmentService.getAllAppointmentsForMyPosts();
      } catch (e) {
        // Nếu endpoint chưa có, chỉ log warning và tiếp tục với appointments user đã tạo
        debugPrint('[AppointmentsListScreen] Warning: Could not load post owner appointments: $e');
        debugPrint('[AppointmentsListScreen] Continuing with user created appointments only');
      }
      
      // Merge 2 danh sách và loại bỏ duplicate (theo appointment ID)
      final allAppointmentsMap = <int, Map<String, dynamic>>{};
      
      // Thêm appointments user đã tạo
      for (var appointment in userCreatedAppointments) {
        final id = appointment['id'] is int 
            ? appointment['id'] 
            : int.tryParse(appointment['id'].toString());
        if (id != null) {
          allAppointmentsMap[id] = appointment;
        }
      }
      
      // Thêm appointments cho bài post của user (override nếu trùng ID)
      for (var appointment in postOwnerAppointments) {
        final id = appointment['id'] is int 
            ? appointment['id'] 
            : int.tryParse(appointment['id'].toString());
        if (id != null) {
          allAppointmentsMap[id] = appointment;
        }
      }
      
      final appointments = allAppointmentsMap.values.toList();
      
      // Cache post ownerships để kiểm tra quyền
      await _cachePostOwnerships(appointments);
      
      // Debug: In ra để kiểm tra dữ liệu
      debugPrint('[AppointmentsListScreen] Current User ID: $_currentUserId');
      debugPrint('[AppointmentsListScreen] User created appointments: ${userCreatedAppointments.length}');
      debugPrint('[AppointmentsListScreen] Post owner appointments: ${postOwnerAppointments.length}');
      debugPrint('[AppointmentsListScreen] Total merged appointments: ${appointments.length}');
      
      for (var appointment in appointments) {
        final appointmentId = appointment['id'];
        final appointmentUserId = appointment['userId'];
        final appointmentPostId = appointment['postId'];
        final appointmentStatus = _getStatus(appointment);
        final isCreatedByUser = appointmentUserId == _currentUserId;
        final isPostOwner = _postOwnershipCache[appointmentPostId] == _currentUserId;
        
        debugPrint('[AppointmentsListScreen] Appointment $appointmentId:');
        debugPrint('  - UserId: $appointmentUserId (Created by user: $isCreatedByUser)');
        debugPrint('  - PostId: $appointmentPostId (Post owner: ${_postOwnershipCache[appointmentPostId]}, Is owner: $isPostOwner)');
        debugPrint('  - Status: $appointmentStatus');
        debugPrint('  - Can manage: ${_canManageAppointment(appointment)}');
      }
      
      if (mounted) {
        setState(() {
          _allAppointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAppointment(int appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Chấp nhận lịch hẹn', style: AppTextStyles.h6),
        content: Text(
          'Bạn có chắc chắn muốn chấp nhận lịch hẹn này?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Không', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Chấp nhận',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Kiểm tra lại trạng thái trước khi gửi request
      final currentAppointment = _allAppointments.firstWhere(
        (app) => (app['id'] is int ? app['id'] : int.tryParse(app['id'].toString())) == appointmentId,
        orElse: () => {},
      );
      
      if (currentAppointment.isNotEmpty && _getStatus(currentAppointment) != 'PENDING') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lịch hẹn này đã được xử lý rồi'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      await _appointmentService.confirmAppointment(appointmentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chấp nhận lịch hẹn'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Clear cache và reload lại để cập nhật trạng thái
        _postOwnershipCache.clear();
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chấp nhận lịch hẹn: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectAppointment(int appointmentId) async {
    // Xác nhận trước khi từ chối
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Từ chối lịch hẹn', style: AppTextStyles.h6),
        content: Text(
          'Bạn có chắc chắn muốn từ chối lịch hẹn này?',
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
              'Từ chối',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Kiểm tra lại trạng thái trước khi gửi request
      final currentAppointment = _allAppointments.firstWhere(
        (app) => (app['id'] is int ? app['id'] : int.tryParse(app['id'].toString())) == appointmentId,
        orElse: () => {},
      );
      
      if (currentAppointment.isNotEmpty && _getStatus(currentAppointment) != 'PENDING') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lịch hẹn này đã được xử lý rồi'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      await _appointmentService.rejectAppointment(appointmentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối lịch hẹn'),
            backgroundColor: AppColors.error,
          ),
        );
        
        // Clear cache và reload lại để cập nhật trạng thái
        _postOwnershipCache.clear();
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi từ chối lịch hẹn: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Lấy status của appointment
  String _getStatus(Map<String, dynamic> appointment) {
    // Thử cả camelCase và PascalCase vì API có thể trả về một trong hai
    final statusValue = appointment['status'] ?? appointment['Status'];
    if (statusValue == null) return 'PENDING';
    
    // Nếu là string, trả về trực tiếp (uppercase)
    if (statusValue is String) {
      return statusValue.toUpperCase();
    }
    
    // Nếu là int (enum value), convert sang string
    if (statusValue is int) {
      switch (statusValue) {
        case 0:
          return 'PENDING';
        case 1:
          return 'ACCEPTED';
        case 2:
          return 'REJECTED';
        default:
          return 'PENDING';
      }
    }
    
    return 'PENDING';
  }

  /// Lọc lịch hẹn theo trạng thái
  List<Map<String, dynamic>> _getAppointmentsByStatus(String status) {
    switch (status) {
      case 'confirmed':
        // Lịch hẹn đã chấp nhận: Status = ACCEPTED
        return _allAppointments.where((appointment) {
          final appointmentStatus = _getStatus(appointment);
          final result = appointmentStatus == 'ACCEPTED';
          debugPrint('[Filter] Appointment ${appointment['id']} - confirmed: status=$appointmentStatus => $result');
          return result;
        }).toList();
      case 'pending':
        // Lịch hẹn chờ xác nhận: Status = PENDING
        return _allAppointments.where((appointment) {
          final appointmentStatus = _getStatus(appointment);
          final result = appointmentStatus == 'PENDING';
          debugPrint('[Filter] Appointment ${appointment['id']} - pending: status=$appointmentStatus => $result');
          return result;
        }).toList();
      case 'rejected':
        // Lịch hẹn bị từ chối: Status = REJECTED
        return _allAppointments.where((appointment) {
          final appointmentStatus = _getStatus(appointment);
          final result = appointmentStatus == 'REJECTED';
          debugPrint('[Filter] Appointment ${appointment['id']} - rejected: status=$appointmentStatus => $result');
          return result;
        }).toList();
      default:
        return [];
    }
  }


  /// Lấy text badge theo trạng thái tab
  String _getTabStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Đã chấp nhận';
      case 'pending':
        return 'Chờ xác nhận';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return 'Không xác định';
    }
  }

  /// Lấy icon theo trạng thái tab
  IconData _getTabStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return FontAwesomeIcons.circleCheck;
      case 'pending':
        return FontAwesomeIcons.clock;
      case 'rejected':
        return FontAwesomeIcons.circleXmark;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  /// Cache post ownerships để kiểm tra quyền nhanh hơn
  Future<void> _cachePostOwnerships(List<Map<String, dynamic>> appointments) async {
    if (_currentUserId == null) return;
    
    // Lấy danh sách post IDs cần kiểm tra
    final postIds = appointments
        .map((app) => app['postId'])
        .where((id) => id != null)
        .map((id) => id is int ? id : int.tryParse(id.toString()))
        .where((id) => id != null)
        .cast<int>()
        .toSet();
    
    // Fetch ownership cho các post chưa có trong cache
    for (final postId in postIds) {
      if (!_postOwnershipCache.containsKey(postId)) {
        try {
          final post = await _postService.getPostById(postId);
          _postOwnershipCache[postId] = post.userId;
        } catch (e) {
          debugPrint('Error loading post $postId: $e');
        }
      }
    }
  }

  /// Kiểm tra xem user hiện tại có phải là chủ bài post không
  /// Chỉ chủ bài post mới có thể confirm/reject appointments
  bool _canManageAppointment(Map<String, dynamic> appointment) {
    if (_currentUserId == null) return false;
    
    final postId = appointment['postId'];
    if (postId == null) return false;
    
    final postIdInt = postId is int ? postId : int.tryParse(postId.toString());
    if (postIdInt == null) return false;
    
    final postOwnerId = _postOwnershipCache[postIdInt];
    return postOwnerId == _currentUserId;
  }

  /// Navigate đến màn hình chat
  /// Logic: 
  /// - Nếu user là người đặt lịch hẹn → nhắn tin với chủ bài post
  /// - Nếu user là chủ bài post → nhắn tin với người đặt lịch hẹn
  Future<void> _navigateToChat(Map<String, dynamic> appointment) async {
    if (_currentUserId == null) return;
    
    final postId = appointment['postId'];
    final appointmentUserId = appointment['userId'];
    
    if (postId == null || appointmentUserId == null) return;
    
    final postIdInt = postId is int ? postId : int.tryParse(postId.toString());
    if (postIdInt == null) return;
    
    // Xác định người nhận tin nhắn
    String? userName;
    String? userAvatar;
    
    final appointmentUserIdInt = appointmentUserId is int 
        ? appointmentUserId 
        : int.tryParse(appointmentUserId.toString());
    if (appointmentUserIdInt == null) return;
    
    // Xác định user hiện tại là người đặt lịch hay chủ bài post
    final isCreatedByUser = appointmentUserIdInt == _currentUserId;
    final postOwnerId = _postOwnershipCache[postIdInt];
    final isPostOwner = postOwnerId == _currentUserId;
    
    // Hiển thị loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Lấy post details để lấy thông tin user
      final post = await _postService.getPostById(postIdInt);
      
      int finalOtherUserId;
      if (isCreatedByUser) {
        // User là người đặt lịch hẹn → nhắn tin với chủ bài post
        finalOtherUserId = postOwnerId ?? post.userId;
        userName = post.user?.name;
        userAvatar = post.user?.avatarUrl;
      } else if (isPostOwner) {
        // User là chủ bài post → nhắn tin với người đặt lịch hẹn
        finalOtherUserId = appointmentUserIdInt;
        // Fetch thông tin user đặt lịch hẹn từ API
        try {
          final appointmentUser = await _userService.getUserById(appointmentUserIdInt);
          userName = appointmentUser.name;
          userAvatar = appointmentUser.avatarUrl;
        } catch (e) {
          debugPrint('Error fetching appointment user info: $e');
          // Nếu không fetch được, vẫn tiếp tục với userName và userAvatar = null
          // ChatScreen sẽ xử lý việc hiển thị
        }
      } else {
        // Trường hợp không xác định được (không nên xảy ra)
        if (!mounted) return;
        Navigator.pop(context); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xác định người nhận tin nhắn'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading dialog

      // Tạo ConversationId chỉ từ userId (không có postId)
      final minId = _currentUserId! < finalOtherUserId 
          ? _currentUserId! 
          : finalOtherUserId;
      final maxId = _currentUserId! > finalOtherUserId 
          ? _currentUserId! 
          : finalOtherUserId;
      final conversationId = '$minId' '_' '$maxId';

      // Navigate đến ChatScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: conversationId,
            otherUserId: finalOtherUserId,
            postId: postIdInt, // Vẫn truyền để hiển thị thông tin post nếu cần
            userName: userName,
            userAvatar: userAvatar,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi mở chat: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Navigate đến màn hình chi tiết bài post
  void _viewPost(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsScreen(
          propertyId: postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Lịch hẹn của tôi',
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(FontAwesomeIcons.circleCheck),
              text: 'Đã chấp nhận',
            ),
            Tab(
              icon: Icon(FontAwesomeIcons.clock),
              text: 'Chờ xác nhận',
            ),
            Tab(
              icon: Icon(FontAwesomeIcons.circleXmark),
              text: 'Bị từ chối',
            ),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.triangleExclamation,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const Gap(16),
                      Text(
                        'Lỗi tải dữ liệu',
                        style: AppTextStyles.h6,
                      ),
                      const Gap(8),
                      Text(
                        _error!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(24),
                      ElevatedButton(
                        onPressed: _loadAppointments,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentsList('confirmed'),
                      _buildAppointmentsList('pending'),
                      _buildAppointmentsList('rejected'),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAppointmentsList(String status) {
    final appointments = _getAppointmentsByStatus(status);

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              _getTabStatusIcon(status),
              size: 64,
              color: AppColors.textHint,
            ),
            const Gap(16),
            Text(
              'Chưa có lịch hẹn ${_getTabStatusText(status).toLowerCase()}',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final postId = appointment['postId']?.toString();
        final isLastItem = index == appointments.length - 1;
        
        // Chỉ hiển thị button "Đồng ý" và "Từ chối" nếu user là chủ bài post
        final canManage = _canManageAppointment(appointment);

        final isFirstItem = index == 0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppointmentCard(
              isFirstItem: isFirstItem,
              appointment: appointment,
              status: status,
              onConfirm: status == 'pending' &&
                      _getStatus(appointment) == 'PENDING' &&
                      canManage
                  ? () => _confirmAppointment(appointment['id'] as int)
                  : null,
              onReject: status == 'pending' &&
                      _getStatus(appointment) == 'PENDING' &&
                      canManage
                  ? () => _rejectAppointment(appointment['id'] as int)
                  : null,
              onNavigateToChat: postId != null
                  ? () => _navigateToChat(appointment)
                  : null,
              onViewPost: postId != null
                  ? () => _viewPost(postId)
                  : null,
            ),
            // Divider line giữa các card (không hiển thị ở item cuối)
            if (!isLastItem)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
          ],
        );
      },
    );
  }
}

