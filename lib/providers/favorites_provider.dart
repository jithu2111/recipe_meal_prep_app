import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final _storage = StorageService();
  Set<String> _favoriteIds = {};
  bool _isLoaded = false;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoaded => _isLoaded;

  // Check if a recipe is favorited
  bool isFavorite(String recipeId) {
    return _favoriteIds.contains(recipeId);
  }

  // Load favorites from storage
  Future<void> loadFavorites() async {
    try {
      _favoriteIds = await _storage.getFavorites();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String recipeId) async {
    try {
      if (_favoriteIds.contains(recipeId)) {
        // Remove from favorites
        _favoriteIds.remove(recipeId);
        await _storage.removeFavorite(recipeId);
      } else {
        // Add to favorites
        _favoriteIds.add(recipeId);
        await _storage.addFavorite(recipeId);
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  // Add to favorites
  Future<void> addFavorite(String recipeId) async {
    try {
      if (!_favoriteIds.contains(recipeId)) {
        _favoriteIds.add(recipeId);
        await _storage.addFavorite(recipeId);
        notifyListeners();
      }
    } catch (e) {
      print('Error adding favorite: $e');
    }
  }

  // Remove from favorites
  Future<void> removeFavorite(String recipeId) async {
    try {
      if (_favoriteIds.contains(recipeId)) {
        _favoriteIds.remove(recipeId);
        await _storage.removeFavorite(recipeId);
        notifyListeners();
      }
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  // Get count of favorites
  int get favoriteCount => _favoriteIds.length;
}