import 'package:flutter/material.dart';

import '../../widgets/common/post_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../post/post_details_screen.dart';
import '../../../core/models/post_model.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

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
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<int?>(
        future: AuthStorageService.getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userId = snapshot.data;
          if (userId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Yêu cầu đăng nhập',
                    style: AppTextStyles.h6,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn cần đăng nhập để xem danh sách yêu thích',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            );
          }
          
          return ValueListenableBuilder<List<PostModel>>(
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
                padding: const EdgeInsets.all(20),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final property = favorites[index];
                  return PostCard(
                    property: property,
                    isFavorite: true,
                    margin: EdgeInsets.only(bottom: index < favorites.length - 1 ? 16 : 0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailsScreen(
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
          );
        },
      ),
    );
  }
}

