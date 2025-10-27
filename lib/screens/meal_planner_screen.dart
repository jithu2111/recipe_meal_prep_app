import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/sample_recipes.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../services/storage_service.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> with AutomaticKeepAliveClientMixin {
  final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Map<String, Map<String, Recipe?>> _mealPlan = {};
  final List<MealPlan> _mealPlans = [];
  final _storage = StorageService();
  final _uuid = const Uuid();

  @override
  bool get wantKeepAlive => false; // Don't keep alive to force refresh

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
    _loadMealPlans();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when screen becomes visible
    _loadMealPlans();
  }

  Future<void> _loadMealPlans() async {
    final savedPlans = await _storage.getMealPlans();
    final recipes = SampleRecipes.getRecipes();

    if (mounted) {
      setState(() {
        _mealPlans.clear();
        _mealPlans.addAll(savedPlans);

        // Clear existing meal plan first
        for (var day in daysOfWeek) {
          _mealPlan[day] = {
            'Breakfast': null,
            'Lunch': null,
            'Dinner': null,
          };
        }

        // Reconstruct meal plan from saved data
        for (var plan in savedPlans) {
          final recipe = recipes.firstWhere(
            (r) => r.id == plan.recipeId,
            orElse: () => recipes.first,
          );
          final dayIndex = plan.date.weekday - 1; // 1 = Monday, 7 = Sunday
          if (dayIndex >= 0 && dayIndex < daysOfWeek.length) {
            final day = daysOfWeek[dayIndex];
            final mealType = _getMealTypeString(plan.mealType);
            _mealPlan[day]![mealType] = recipe;
          }
        }
      });
    }
  }


  String _getMealTypeString(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
    }
  }

  MealType _getMealTypeEnum(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return MealType.breakfast;
      case 'Lunch':
        return MealType.lunch;
      case 'Dinner':
        return MealType.dinner;
      default:
        return MealType.breakfast;
    }
  }

  int _getDayIndex(String day) {
    return daysOfWeek.indexOf(day);
  }

  DateTime _getDateForDay(String day) {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final dayIndex = _getDayIndex(day);
    final difference = dayIndex - (currentWeekday - 1);
    return now.add(Duration(days: difference));
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

      // Create and save meal plan
      final date = _getDateForDay(day);
      final mealTypeEnum = _getMealTypeEnum(mealType);

      // Remove existing plan for this day/meal if any
      await _storage.deleteMealPlanByDateAndType(date, mealTypeEnum);
      _mealPlans.removeWhere((plan) =>
          plan.date.day == date.day &&
          plan.date.month == date.month &&
          plan.date.year == date.year &&
          plan.mealType == mealTypeEnum);

      // Add new plan
      final newPlan = MealPlan(
        id: _uuid.v4(),
        date: date,
        mealType: mealTypeEnum,
        recipeId: selectedRecipe.id,
      );
      _mealPlans.add(newPlan);

      await _storage.insertMealPlan(newPlan);
    }
  }

  void _removeRecipe(String day, String mealType) async {
    setState(() {
      _mealPlan[day]![mealType] = null;
    });

    // Remove from saved meal plans
    final date = _getDateForDay(day);
    final mealTypeEnum = _getMealTypeEnum(mealType);

    await _storage.deleteMealPlanByDateAndType(date, mealTypeEnum);
    _mealPlans.removeWhere((plan) =>
        plan.date.day == date.day &&
        plan.date.month == date.month &&
        plan.date.year == date.year &&
        plan.mealType == mealTypeEnum);
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