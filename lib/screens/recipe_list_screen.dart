import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sample_recipes.dart';
import '../widgets/recipe_card.dart';
import '../widgets/filter_panel.dart';
import 'recipe_detail_screen.dart';
import 'settings_screen.dart';
import '../services/share_service.dart';
import '../providers/favorites_provider.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final List<String> _selectedDietaryTags = [];
  String? _selectedCuisine;
  String? _selectedCookingTime;
  bool _showFilters = false;
  final _shareService = ShareService();

  void _toggleDietaryTag(String tag) {
    setState(() {
      if (_selectedDietaryTags.contains(tag)) {
        _selectedDietaryTags.remove(tag);
      } else {
        _selectedDietaryTags.add(tag);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedDietaryTags.clear();
      _selectedCuisine = null;
      _selectedCookingTime = null;
    });
  }

  List<dynamic> _getFilteredRecipes(List<dynamic> recipes) {
    return recipes.where((recipe) {
      // Filter by dietary tags
      if (_selectedDietaryTags.isNotEmpty) {
        bool hasDietaryTag = _selectedDietaryTags.any(
          (tag) => recipe.dietaryTags.contains(tag),
        );
        if (!hasDietaryTag) return false;
      }

      // Filter by cuisine
      if (_selectedCuisine != null && recipe.cuisine != _selectedCuisine) {
        return false;
      }

      // Filter by cooking time
      if (_selectedCookingTime != null) {
        int maxTime = 0;
        if (_selectedCookingTime == 'Under 15 min') {
          maxTime = 15;
        } else if (_selectedCookingTime == 'Under 30 min') {
          maxTime = 30;
        } else if (_selectedCookingTime == 'Under 45 min') {
          maxTime = 45;
        } else if (_selectedCookingTime == 'Under 60 min') {
          maxTime = 60;
        } else if (_selectedCookingTime == '60+ min') {
          return recipe.cookingTime >= 60;
        }
        if (maxTime > 0 && recipe.cookingTime > maxTime) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allRecipes = SampleRecipes.getRecipes();
    final recipes = _getFilteredRecipes(allRecipes);
    final hasActiveFilters = _selectedDietaryTags.isNotEmpty ||
        _selectedCuisine != null ||
        _selectedCookingTime != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                tooltip: 'Filters',
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        '${_selectedDietaryTags.length + (_selectedCuisine != null ? 1 : 0) + (_selectedCookingTime != null ? 1 : 0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Panel
          if (_showFilters)
            FilterPanel(
              selectedDietaryTags: _selectedDietaryTags,
              selectedCuisine: _selectedCuisine,
              selectedCookingTime: _selectedCookingTime,
              onDietaryTagToggle: _toggleDietaryTag,
              onCuisineChanged: (value) {
                setState(() {
                  _selectedCuisine = value;
                });
              },
              onCookingTimeChanged: (value) {
                setState(() {
                  _selectedCookingTime = value;
                });
              },
              onClearFilters: _clearFilters,
            ),

          // Recipe count header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: hasActiveFilters ? Theme.of(context).colorScheme.primaryContainer : null,
            child: Row(
              children: [
                Icon(
                  Icons.restaurant,
                  size: 20,
                  color: hasActiveFilters
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${recipes.length} ${recipes.length == 1 ? 'Recipe' : 'Recipes'}${hasActiveFilters ? ' (filtered)' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasActiveFilters
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Recipe List
          Expanded(
            child: recipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recipes found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (hasActiveFilters)
                          ElevatedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  )
                : Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: RecipeCard(
                              recipe: recipe,
                              isFavorite: favoritesProvider.isFavorite(recipe.id),
                              canCookNow: false, // Will be implemented with pantry integration
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetailScreen(recipe: recipe),
                                  ),
                                );
                              },
                              onFavorite: () async {
                                await favoritesProvider.toggleFavorite(recipe.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        favoritesProvider.isFavorite(recipe.id)
                                            ? 'Added to favorites'
                                            : 'Removed from favorites',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              onShare: () => _shareService.shareRecipe(recipe),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}