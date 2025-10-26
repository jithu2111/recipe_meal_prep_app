import 'package:flutter/material.dart';
import '../data/sample_recipes.dart';
import '../widgets/recipe_card.dart';
import '../widgets/filter_panel.dart';
import 'recipe_detail_screen.dart';
import 'meal_planner_screen.dart';
import 'favorites_screen.dart';

class TestRecipeCardScreen extends StatefulWidget {
  const TestRecipeCardScreen({super.key});

  @override
  State<TestRecipeCardScreen> createState() => _TestRecipeCardScreenState();
}

class _TestRecipeCardScreenState extends State<TestRecipeCardScreen> {
  final Set<String> _favorites = {};
  final List<String> _selectedDietaryTags = [];
  String? _selectedCuisine;
  String? _selectedCookingTime;
  bool _showFilters = false;

  void _toggleFavorite(String recipeId) {
    setState(() {
      if (_favorites.contains(recipeId)) {
        _favorites.remove(recipeId);
      } else {
        _favorites.add(recipeId);
      }
    });
  }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Cards Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
            tooltip: 'Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealPlannerScreen(),
                ),
              );
            },
            tooltip: 'Meal Planner',
          ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Toggle Filters',
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
          // Recipe List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RecipeCard(
                    recipe: recipe,
                    isFavorite: _favorites.contains(recipe.id),
                    canCookNow: false, // Will be implemented with pantry integration
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                    onFavorite: () => _toggleFavorite(recipe.id),
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