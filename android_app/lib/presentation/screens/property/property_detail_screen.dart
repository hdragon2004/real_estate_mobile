import 'package:flutter/material.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../chat/chat_screen.dart';
import 'image_gallery_screen.dart';
import 'map_screen.dart';

/// Màn hình Chi tiết bất động sản
class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _isLoading = false;
  bool _isFavorite = false;
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  final List<String> _images = []; // TODO: Load từ API

  @override
  void initState() {
    super.initState();
    _loadPropertyDetail();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadPropertyDetail() async {
    setState(() => _isLoading = true);
    // TODO: Gọi API lấy chi tiết
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    // TODO: Gọi API toggle favorite
  }

  void _openImageGallery() {
    if (_images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryScreen(
          images: _images,
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          propertyId: widget.propertyId,
        ),
      ),
    );
  }

  void _contactOwner() {
    // Mở chat với chủ tin
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: 'owner_${widget.propertyId}',
          userName: 'Nguyễn Văn A',
          userAvatar: null,
        ),
      ),
    );
  }

  void _callOwner() {
    // TODO: Gọi điện cho chủ tin
    // launchUrl(Uri.parse('tel:0123456789'));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const LoadingIndicator(),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar với image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _images.isEmpty
                  ? Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 80),
                    )
                  : PageView.builder(
                      controller: _imageController,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: _openImageGallery,
                          child: Image.network(
                            _images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image, size: 80),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Share property
                },
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image indicators
                  if (_images.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _images.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Title & Price
                  const Text(
                    'Căn hộ cao cấp tại Quận 1',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '15 tỷ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '123 Đường ABC, Quận 1, TP.HCM',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Property info
                  _buildInfoRow(Icons.bed, 'Phòng ngủ', '3'),
                  _buildInfoRow(Icons.bathtub, 'Phòng tắm', '2'),
                  _buildInfoRow(Icons.square_foot, 'Diện tích', '120 m²'),
                  _buildInfoRow(Icons.calendar_today, 'Ngày đăng', '15/01/2024'),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Căn hộ cao cấp với đầy đủ tiện nghi, view đẹp, gần trung tâm. Phòng khách rộng rãi, phòng ngủ thoáng mát, bếp hiện đại. Khu vực an ninh tốt, gần trường học, bệnh viện, siêu thị.',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  // Thông tin liên hệ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin liên hệ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildContactRow(Icons.person, 'Nguyễn Văn A'),
                        _buildContactRow(Icons.phone, '0123456789'),
                        _buildContactRow(Icons.email, 'owner@example.com'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Map button
                  AppButton(
                    text: 'Xem vị trí trên bản đồ',
                    onPressed: _openMap,
                    isOutlined: true,
                    icon: Icons.map,
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Gọi điện',
                          onPressed: _callOwner,
                          isOutlined: true,
                          icon: Icons.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: 'Nhắn tin',
                          onPressed: _contactOwner,
                          icon: Icons.chat,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

