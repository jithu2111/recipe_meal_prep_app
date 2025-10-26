import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../data/sample_recipes.dart';
import '../services/storage_service.dart';
import '../services/share_service.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<Recipe> _favorites = [];
  final _storage = StorageService();
  final _shareService = ShareService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    // Get favorite recipe IDs from storage
    final favoriteIds = await _storage.getFavorites();

    // Get all recipes
    final allRecipes = SampleRecipes.getRecipes();

    // Filter recipes that are in favorites
    final favoriteRecipes = allRecipes
        .where((recipe) => favoriteIds.contains(recipe.id))
        .toList();

    setState(() {
      _favorites.clear();
      _favorites.addAll(favoriteRecipes);
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(Recipe recipe, int index) async {
    await _storage.removeFavorite(recipe.id);

    setState(() {
      _favorites.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.title} removed from favorites'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // Re-add to favorites
              await _storage.addFavorite(recipe.id);
              _loadFavorites();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start adding recipes to your favorites!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header with count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_favorites.length} ${_favorites.length == 1 ? 'Favorite Recipe' : 'Favorite Recipes'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Recipe List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final recipe = _favorites[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: RecipeCard(
                              recipe: recipe,
                              isFavorite: true,
                              canCookNow: false, // Will be implemented with pantry integration
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetailScreen(recipe: recipe),
                                  ),
                                );
                                // Reload favorites in case they were changed in detail screen
                                _loadFavorites();
                              },
                              onFavorite: () => _removeFavorite(recipe, index),
                              onShare: () => _shareService.shareRecipe(recipe),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}