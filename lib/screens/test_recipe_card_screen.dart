import 'package:flutter/material.dart';
import '../data/sample_recipes.dart';
import '../widgets/recipe_card.dart';
import '../widgets/filter_panel.dart';

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

  @override
  Widget build(BuildContext context) {
    final recipes = SampleRecipes.getRecipes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Cards Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
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
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tapped: ${recipe.title}'),
                          duration: const Duration(seconds: 1),
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