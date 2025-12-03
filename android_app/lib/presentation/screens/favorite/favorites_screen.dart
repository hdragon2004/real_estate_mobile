import 'package:flutter/material.dart';
import '../../widgets/common/property_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../property/property_detail_screen.dart';

/// Màn hình Danh sách tin đã lưu (Yêu thích)
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = false;
  final List<PropertyModel> _favorites = _getSampleFavorites(); // Dữ liệu mẫu

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    // TODO: Gọi API lấy danh sách yêu thích
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // Dữ liệu mẫu
  static List<PropertyModel> _getSampleFavorites() {
    return [
      PropertyModel(
        id: '2',
        title: 'Nhà phố mặt tiền Quận 3',
        address: '456 Đường Lê Văn Sỹ, Quận 3, TP.HCM',
        price: 25000000000,
        imageUrl: null,
        bedrooms: 4,
        bathrooms: 3,
        area: 200,
        isFavorite: true,
      ),
      PropertyModel(
        id: '5',
        title: 'Chung cư hiện đại Quận Bình Thạnh',
        address: '654 Đường Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM',
        price: 8000000000,
        imageUrl: null,
        bedrooms: 2,
        bathrooms: 2,
        area: 80,
        isFavorite: true,
      ),
    ];
  }

  Future<void> _removeFavorite(PropertyModel property) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Xóa khỏi yêu thích',
      message: 'Bạn có chắc chắn muốn xóa bất động sản này khỏi danh sách yêu thích?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    );

    if (confirmed == true) {
      setState(() {
        _favorites.removeWhere((p) => p.id == property.id);
      });
      // TODO: Gọi API xóa favorite
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu thích'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _favorites.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'Chưa có yêu thích',
                  message: 'Thêm bất động sản vào yêu thích để xem lại sau',
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final property = _favorites[index];
                      return PropertyCard(
                        property: property,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailScreen(
                                propertyId: property.id,
                              ),
                            ),
                          );
                        },
                        onFavoriteTap: () => _removeFavorite(property),
                      );
                    },
                  ),
                ),
    );
  }
}

