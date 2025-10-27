import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../services/share_service.dart';
import '../services/storage_service.dart';
import '../providers/favorites_provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _shareService = ShareService();
  final _storage = StorageService();
  final _uuid = const Uuid();
  final GlobalKey _screenshotKey = GlobalKey();

  final List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _showAddToMealPlanDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MealPlanSelectionDialog(),
    );

    if (result != null) {
      final day = result['day'] as String;
      final mealType = result['mealType'] as MealType;

      try {
        // Calculate the date for the selected day
        final date = _getDateForDay(day);

        // Remove existing plan for this day/meal if any
        await _storage.deleteMealPlanByDateAndType(date, mealType);

        // Create and save new meal plan
        final newPlan = MealPlan(
          id: _uuid.v4(),
          date: date,
          mealType: mealType,
          recipeId: widget.recipe.id,
        );

        await _storage.insertMealPlan(newPlan);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to ${_getMealTypeString(mealType)} on $day'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add to meal plan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = favoritesProvider.isFavorite(widget.recipe.id);

        return Scaffold(
          body: RepaintBoundary(
            key: _screenshotKey,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  actions: [
                // Share button with dropdown menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.share, color: Colors.white),
                  tooltip: 'Share Recipe',
                  onSelected: (value) {
                    switch (value) {
                      case 'share':
                        _shareService.shareRecipe(widget.recipe);
                        break;
                      case 'copy':
                        _shareService.copyRecipeLink(widget.recipe, context);
                        break;
                      case 'image':
                        _shareService.shareAsImage(_screenshotKey, widget.recipe, context);
                        break;
                      case 'more':
                        _shareService.showShareOptions(context, widget.recipe, _screenshotKey);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Share Text'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 12),
                          Text('Copy Link'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'image',
                      child: Row(
                        children: [
                          Icon(Icons.image, size: 20),
                          SizedBox(width: 12),
                          Text('Share as Image'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'more',
                      child: Row(
                        children: [
                          Icon(Icons.more_horiz, size: 20),
                          SizedBox(width: 12),
                          Text('More Options'),
                        ],
                      ),
                    ),
                  ],
                ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () async {
                  await favoritesProvider.toggleFavorite(widget.recipe.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          favoritesProvider.isFavorite(widget.recipe.id)
                              ? 'Added to favorites'
                              : 'Removed from favorites',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.recipe.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cooking Time and Nutrition Facts
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${widget.recipe.cookingTime} min',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Cooking Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.recipe.rating.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Rating',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.recipe.nutritionFacts != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.restaurant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.recipe.nutritionFacts!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Ingredients Section
                    Text(
                      'Ingredients',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.recipe.ingredients.map((ingredient) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ingredient,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    // Preparation Steps Section
                    Text(
                      'Preparation Steps',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.recipe.steps.asMap().entries.map((entry) {
                      int index = entry.key;
                      String step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ]),
          ),
          ],
        ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddToMealPlanDialog,
          icon: const Icon(Icons.calendar_today),
          label: const Text('Add to Meal Plan'),
          heroTag: 'add_to_meal_plan_fab',
        ),
      );
    },
    );
  }
}

// Dialog for selecting day and meal type
class _MealPlanSelectionDialog extends StatefulWidget {
  @override
  State<_MealPlanSelectionDialog> createState() => _MealPlanSelectionDialogState();
}

class _MealPlanSelectionDialogState extends State<_MealPlanSelectionDialog> {
  final List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String? selectedDay;
  MealType? selectedMealType;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Meal Plan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Day:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: daysOfWeek.map((day) {
              return ChoiceChip(
                label: Text(day),
                selected: selectedDay == day,
                onSelected: (selected) {
                  setState(() {
                    selectedDay = selected ? day : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Meal:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              RadioListTile<MealType>(
                title: const Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Breakfast'),
                  ],
                ),
                value: MealType.breakfast,
                groupValue: selectedMealType,
                onChanged: (value) {
                  setState(() {
                    selectedMealType = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<MealType>(
                title: const Row(
                  children: [
                    Icon(Icons.wb_sunny, size: 20),
                    SizedBox(width: 8),
                    Text('Lunch'),
                  ],
                ),
                value: MealType.lunch,
                groupValue: selectedMealType,
                onChanged: (value) {
                  setState(() {
                    selectedMealType = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<MealType>(
                title: const Row(
                  children: [
                    Icon(Icons.nights_stay_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Dinner'),
                  ],
                ),
                value: MealType.dinner,
                groupValue: selectedMealType,
                onChanged: (value) {
                  setState(() {
                    selectedMealType = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedDay != null && selectedMealType != null
              ? () {
                  Navigator.pop(context, {
                    'day': selectedDay,
                    'mealType': selectedMealType,
                  });
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}