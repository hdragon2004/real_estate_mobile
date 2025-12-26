import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../repositories/favorite_repository.dart';
import '../repositories/api_exception.dart';
import 'base_service.dart';

class FavoriteService extends BaseService {
  late FavoriteRepository _repository;
  FavoriteService() {
    _repository = FavoriteRepository();
  }
  final ValueNotifier<List<PostModel>> _favoritesNotifier = ValueNotifier<List<PostModel>>([]);

  ValueListenable<List<PostModel>> get favoritesListenable => _favoritesNotifier;

  List<PostModel> get favorites => List.unmodifiable(_favoritesNotifier.value);

  bool isFavorite(int postId) {
    return _favoritesNotifier.value.any((post) => post.id == postId);
  }

  /// Load favorites từ backend
  Future<void> loadFavorites(int userId) async {
    await safeApiCall(() async {
      final response = await _repository.getFavoritesByUser(userId);
      final favoritesData = unwrapListResponse(response);
      
      // Parse từ Favorite objects (có chứa Post) thành PostModel
      final posts = <PostModel>[];
      for (final fav in favoritesData) {
        try {
          if (fav['post'] != null && fav['post'] is Map<String, dynamic>) {
            final postJson = fav['post'] as Map<String, dynamic>;
            final post = PostModel.fromJson(postJson);
            posts.add(post);
          }
        } catch (e) {
          handleError(ApiException(
            statusCode: 0,
            message: 'Lỗi parse post: ${e.toString()}',
            originalError: e,
          ));
        }
      }
      
      _favoritesNotifier.value = posts;
    });
  }

  /// Toggle favorite - đồng bộ với backend (nếu có userId) hoặc chỉ local
  Future<void> toggleFavorite(PostModel property, [int? userId]) async {
    final isCurrentlyFavorite = isFavorite(property.id);
    
    // Nếu có userId, đồng bộ với backend
    if (userId != null) {
      await safeApiCall(() async {
        if (isCurrentlyFavorite) {
          await _repository.removeFavorite(userId, property.id);
        } else {
          final response = await _repository.addFavorite(userId, property.id);
          unwrapResponse(response);
        }
      });
    }
    
    // Update local state
    final favorites = List<PostModel>.from(_favoritesNotifier.value);
    if (isCurrentlyFavorite) {
      favorites.removeWhere((item) => item.id == property.id);
    } else {
      favorites.insert(0, property);
    }
    _favoritesNotifier.value = favorites;
  }

  /// Remove favorite - đồng bộ với backend (nếu có userId) hoặc chỉ local
  Future<void> removeFavorite(int postId, [int? userId]) async {
    // Nếu có userId, đồng bộ với backend
    if (userId != null) {
      await safeApiCall(() => _repository.removeFavorite(userId, postId));
    }
    
    // Update local state
    final favorites = List<PostModel>.from(_favoritesNotifier.value)
      ..removeWhere((item) => item.id == postId);
    _favoritesNotifier.value = favorites;
  }

  /// Add favorite
  Future<void> addFavorite(PostModel property, int userId) async {
    await safeApiCall(() async {
      final response = await _repository.addFavorite(userId, property.id);
      unwrapResponse(response);
      final favorites = List<PostModel>.from(_favoritesNotifier.value)
        ..insert(0, property);
      _favoritesNotifier.value = favorites;
    });
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
