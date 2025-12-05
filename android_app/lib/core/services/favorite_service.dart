import 'package:flutter/foundation.dart';

import '../models/post_model.dart';

class FavoriteService {
  FavoriteService._();
  static final FavoriteService _instance = FavoriteService._();
  factory FavoriteService() => _instance;

  final ValueNotifier<List<PostModel>> _favoritesNotifier = ValueNotifier<List<PostModel>>([]);

  ValueListenable<List<PostModel>> get favoritesListenable => _favoritesNotifier;

  List<PostModel> get favorites => List.unmodifiable(_favoritesNotifier.value);

  bool isFavorite(int postId) {
    return _favoritesNotifier.value.any((post) => post.id == postId);
  }

  void toggleFavorite(PostModel property) {
    final favorites = List<PostModel>.from(_favoritesNotifier.value);
    final index = favorites.indexWhere((item) => item.id == property.id);
    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.insert(0, property);
    }
    _favoritesNotifier.value = favorites;
  }

  void removeFavorite(int postId) {
    final favorites = List<PostModel>.from(_favoritesNotifier.value)
      ..removeWhere((item) => item.id == postId);
    _favoritesNotifier.value = favorites;
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
