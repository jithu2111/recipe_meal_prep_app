import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../data/sample_recipes.dart';
import '../services/share_service.dart';
import '../providers/favorites_provider.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _shareService = ShareService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          // Get all recipes
          final allRecipes = SampleRecipes.getRecipes();

          // Filter recipes that are in favorites
          final favoriteRecipes = allRecipes
              .where((recipe) => favoritesProvider.isFavorite(recipe.id))
              .toList();

          if (favoriteRecipes.isEmpty) {
            return Center(
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
            );
          }

          return Column(
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
                      '${favoriteRecipes.length} ${favoriteRecipes.length == 1 ? 'Favorite Recipe' : 'Favorite Recipes'}',
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
                  itemCount: favoriteRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = favoriteRecipes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: RecipeCard(
                        recipe: recipe,
                        isFavorite: true,
                        canCookNow: false,
                        heroTagPrefix: 'favorites',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                        },
                        onFavorite: () async {
                          await favoritesProvider.removeFavorite(recipe.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${recipe.title} removed from favorites'),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () async {
                                    await favoritesProvider.addFavorite(recipe.id);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        onShare: () => _shareService.shareRecipe(recipe),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}