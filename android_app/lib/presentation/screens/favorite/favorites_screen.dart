import 'package:flutter/material.dart';

import '../../widgets/common/property_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../property/property_detail_screen.dart';
import '../../../core/models/post_model.dart';
import '../../../core/services/favorite_service.dart';

/// Màn hình Danh sách tin đã lưu (Yêu thích)
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();

  Future<void> _removeFavorite(PostModel property) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Xóa khỏi yêu thích',
      message: 'Bạn có chắc chắn muốn xóa bất động sản này khỏi danh sách yêu thích?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    );

    if (confirmed == true) {
      _favoriteService.removeFavorite(property.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu thích'),
      ),
      body: ValueListenableBuilder<List<PostModel>>(
        valueListenable: _favoriteService.favoritesListenable,
        builder: (context, favorites, _) {
          if (favorites.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'Chưa có yêu thích',
              message: 'Thêm bất động sản vào yêu thích để xem lại sau',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final property = favorites[index];
              return PropertyCard(
                property: property,
                isFavorite: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailScreen(
                        propertyId: property.id.toString(),
                        initialProperty: property,
                      ),
                    ),
                  );
                },
                onFavoriteTap: () => _removeFavorite(property),
              );
            },
          );
        },
      ),
    );
  }
}

