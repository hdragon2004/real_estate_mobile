import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/notification_model.dart';
import '../repositories/favorite_repository.dart';
import 'notification_service.dart';

class FavoriteService {
  FavoriteService._();
  static final FavoriteService _instance = FavoriteService._();
  factory FavoriteService() => _instance;

  final FavoriteRepository _repository = FavoriteRepository();
  final NotificationService _notificationService = NotificationService();
  final ValueNotifier<List<PostModel>> _favoritesNotifier =
      ValueNotifier<List<PostModel>>([]);

  ValueListenable<List<PostModel>> get favoritesListenable =>
      _favoritesNotifier;

  List<PostModel> get favorites => List.unmodifiable(_favoritesNotifier.value);

  bool isFavorite(int postId) {
    return _favoritesNotifier.value.any((post) => post.id == postId);
  }

  /// Load favorites từ backend
  Future<void> loadFavorites(int userId) async {
    try {
      final favoritesData = await _repository.getFavoritesByUser(userId);
      // Parse từ Favorite objects (có chứa Post) thành PostModel
      final posts = favoritesData
          .where((fav) => fav['post'] != null)
          .map((fav) => PostModel.fromJson(fav['post'] as Map<String, dynamic>))
          .toList();
      _favoritesNotifier.value = posts;
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  /// Toggle favorite - đồng bộ với backend (nếu có userId) hoặc chỉ local
  Future<void> toggleFavorite(PostModel property, [int? userId]) async {
    final isCurrentlyFavorite = isFavorite(property.id);

    if (userId != null) {
      try {
        if (isCurrentlyFavorite) {
          await _repository.removeFavorite(userId, property.id);
        } else {
          await _repository.addFavorite(userId, property.id);
        }
      } catch (e) {
        debugPrint('Error toggling favorite: $e');
        // Fallback về local nếu lỗi
      }
    }

    final favorites = List<PostModel>.from(_favoritesNotifier.value);
    if (isCurrentlyFavorite) {
      favorites.removeWhere((item) => item.id == property.id);
    } else {
      favorites.insert(0, property);
    }
    _favoritesNotifier.value = favorites;

    final title = isCurrentlyFavorite
        ? 'Đã xóa khỏi danh sách yêu thích'
        : 'Đã thêm bất động sản vào yêu thích';
    final message = property.title;
    await _notificationService.addLocalNotification(
      title: title,
      message: message,
      type: NotificationType.system,
      postId: property.id,
    );
  }

  /// Remove favorite - đồng bộ với backend (nếu có userId) hoặc chỉ local
  Future<void> removeFavorite(int postId, [int? userId]) async {
    // Nếu có userId, đồng bộ với backend
    if (userId != null) {
      try {
        await _repository.removeFavorite(userId, postId);
      } catch (e) {
        debugPrint('Error removing favorite: $e');
        // Fallback về local nếu lỗi
      }
    }

    // Update local state
    final favorites = List<PostModel>.from(_favoritesNotifier.value)
      ..removeWhere((item) => item.id == postId);
    _favoritesNotifier.value = favorites;
  }

  /// Add favorite
  Future<void> addFavorite(PostModel property, int userId) async {
    try {
      await _repository.addFavorite(userId, property.id);
      final favorites = List<PostModel>.from(_favoritesNotifier.value)
        ..insert(0, property);
      _favoritesNotifier.value = favorites;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      rethrow;
    }
  }

  void upsert(PostModel property) {
    final favorites = List<PostModel>.from(_favoritesNotifier.value);
    final index = favorites.indexWhere((item) => item.id == property.id);
    if (index >= 0) {
      favorites[index] = property;
      _favoritesNotifier.value = favorites;
    }
  }
}
