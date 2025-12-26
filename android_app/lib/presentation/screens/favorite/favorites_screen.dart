import 'package:flutter/material.dart';

import '../../widgets/common/post_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/loading_indicator.dart';
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
  bool _isLoading = true;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_isInitialLoad) {
      setState(() => _isLoading = true);
    }

    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isInitialLoad = false;
          });
        }
        return;
      }
      
      await _favoriteService.loadFavorites(userId);
    } catch (e) {
      // Error đã được xử lý bởi BaseService.handleError
      // Đảm bảo loading state được reset
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  Future<void> _removeFavorite(PostModel property) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Xóa khỏi yêu thích',
      message: 'Bạn có chắc chắn muốn xóa bất động sản này khỏi danh sách yêu thích?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    );

    if (confirmed == true) {
      final userId = await AuthStorageService.getUserId();
      await _favoriteService.removeFavorite(property.id, userId);
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
          if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
            return const LoadingIndicator(message: 'Đang tải danh sách yêu thích...');
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

              return RefreshIndicator(
                onRefresh: _loadFavorites,
                color: AppColors.primary,
                child: ListView.builder(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}

