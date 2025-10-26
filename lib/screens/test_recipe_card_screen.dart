import 'package:flutter/material.dart';
import '../data/sample_recipes.dart';
import '../widgets/recipe_card.dart';

class TestRecipeCardScreen extends StatefulWidget {
  const TestRecipeCardScreen({super.key});

  @override
  State<TestRecipeCardScreen> createState() => _TestRecipeCardScreenState();
}

class _TestRecipeCardScreenState extends State<TestRecipeCardScreen> {
  final Set<String> _favorites = {};

  void _toggleFavorite(String recipeId) {
    setState(() {
      if (_favorites.contains(recipeId)) {
        _favorites.remove(recipeId);
      } else {
        _favorites.add(recipeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipes = SampleRecipes.getRecipes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Cards Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView.builder(
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
    );
  }
}