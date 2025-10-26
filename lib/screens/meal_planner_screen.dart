import 'package:flutter/material.dart';
import '../data/sample_recipes.dart';
import '../models/recipe.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Map<String, Map<String, Recipe?>> _mealPlan = {};

  @override
  void initState() {
    super.initState();
    // Initialize empty meal plan
    for (var day in daysOfWeek) {
      _mealPlan[day] = {
        'Breakfast': null,
        'Lunch': null,
        'Dinner': null,
      };
    }
  }

  void _assignRecipe(String day, String mealType) async {
    final recipes = SampleRecipes.getRecipes();
    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (context) => _RecipeSelectionDialog(recipes: recipes),
    );

    if (selectedRecipe != null) {
      setState(() {
        _mealPlan[day]![mealType] = selectedRecipe;
      });
    }
  }

  void _removeRecipe(String day, String mealType) {
    setState(() {
      _mealPlan[day]![mealType] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Week Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'This Week',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Weekly Calendar Grid
            ...daysOfWeek.map((day) {
              return _buildDayCard(context, day);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, String day) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            _buildMealSlot(context, day, 'Breakfast', Icons.wb_sunny_outlined),
            const SizedBox(height: 8),
            _buildMealSlot(context, day, 'Lunch', Icons.wb_sunny),
            const SizedBox(height: 8),
            _buildMealSlot(context, day, 'Dinner', Icons.nights_stay_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSlot(BuildContext context, String day, String mealType, IconData icon) {
    final assignedRecipe = _mealPlan[day]![mealType];

    return GestureDetector(
      onTap: () => _assignRecipe(day, mealType),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: assignedRecipe != null ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: assignedRecipe != null ? Colors.green[300]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (assignedRecipe != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      assignedRecipe.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (assignedRecipe != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.red[400],
                onPressed: () => _removeRecipe(day, mealType),
              )
            else
              Icon(Icons.add_circle_outline, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _RecipeSelectionDialog extends StatelessWidget {
  final List<Recipe> recipes;

  const _RecipeSelectionDialog({required this.recipes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Recipe',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return ListTile(
                    title: Text(recipe.title),
                    subtitle: Text(
                      '${recipe.cuisine} • ${recipe.cookingTime} min',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(context, recipe),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}