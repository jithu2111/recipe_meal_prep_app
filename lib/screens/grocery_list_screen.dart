import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/grocery_item.dart';
import '../models/pantry_item.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../utils/ingredient_parser.dart';
import '../utils/ingredient_matcher.dart';
import '../data/sample_recipes.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final List<GroceryItem> _groceryItems = [];
  final List<PantryItem> _pantryItems = [];
  final _uuid = const Uuid();
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadGroceryItems();
    _loadPantryItems();
  }

  Future<void> _loadGroceryItems() async {
    final items = await _storage.getGroceryList();
    setState(() {
      _groceryItems.addAll(items);
    });
  }

  Future<void> _loadPantryItems() async {
    final items = await _storage.getPantryItems();
    setState(() {
      _pantryItems.addAll(items);
    });
  }


  // Check if an item is already in pantry
  bool _isInPantry(String itemName) {
    return _pantryItems.any(
      (pantryItem) => pantryItem.name.toLowerCase() == itemName.toLowerCase(),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    String selectedCategory = Constants.groceryCategories.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Grocery Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g., Tomatoes, Chicken',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g., 2, 1.5',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    hintText: 'e.g., kg, L, pieces',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: Constants.groceryCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    quantityController.text.isNotEmpty &&
                    unitController.text.isNotEmpty) {
                  // Check if item is already in pantry
                  if (_isInPantry(nameController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${nameController.text} is already in your pantry!',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    Navigator.pop(context);
                    return;
                  }

                  final newItem = GroceryItem(
                    id: _uuid.v4(),
                    name: nameController.text,
                    quantity: double.tryParse(quantityController.text) ?? 0,
                    unit: unitController.text,
                    category: selectedCategory,
                  );
                  this.setState(() {
                    _groceryItems.add(newItem);
                  });
                  await _storage.insertGroceryItem(newItem);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePurchased(int index) async {
    final updatedItem = _groceryItems[index].copyWith(
      isPurchased: !_groceryItems[index].isPurchased,
    );

    setState(() {
      _groceryItems[index] = updatedItem;
    });

    await _storage.updateGroceryItem(updatedItem);
  }

  Future<void> _generateFromMealPlan() async {
    try {
      // Get all meal plans
      final mealPlans = await _storage.getMealPlans();

      if (mealPlans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No meal plans found. Add recipes to your meal planner first!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get all recipes
      final allRecipes = SampleRecipes.getRecipes();

      // Collect all ingredients from meal plans with recipe names
      final List<ParsedIngredient> parsedIngredients = [];

      for (var mealPlan in mealPlans) {
        final recipe = allRecipes.firstWhere(
          (r) => r.id == mealPlan.recipeId,
          orElse: () => allRecipes.first,
        );

        // Parse each ingredient in the recipe
        for (var ingredientString in recipe.ingredients) {
          final parsed = IngredientParser.parseIngredient(ingredientString);
          // Add recipe name to the parsed ingredient
          final withRecipe = ParsedIngredient(
            name: parsed.name,
            quantity: parsed.quantity,
            unit: parsed.unit,
            category: parsed.category,
            recipeNames: [recipe.title],
          );
          parsedIngredients.add(withRecipe);
        }
      }

      // Merge duplicate ingredients (will combine recipe names)
      final mergedIngredients = IngredientParser.mergeDuplicates(parsedIngredients);

      // Show preview dialog
      _showIngredientPreviewDialog(mergedIngredients);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading meal plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showIngredientPreviewDialog(List<ParsedIngredient> ingredients) {
    final Map<ParsedIngredient, bool> selectedItems = {};
    final Map<ParsedIngredient, ParsedIngredient> modifiedIngredients = {};

    for (var ingredient in ingredients) {
      selectedItems[ingredient] = true; // All selected by default
      modifiedIngredients[ingredient] = ingredient; // Track modifications
    }

    void addIngredientsWithModifications() async {
      // Get the modified versions of selected ingredients
      final selectedModified = selectedItems.entries
          .where((entry) => entry.value)
          .map((entry) => modifiedIngredients[entry.key]!)
          .toList();

      Navigator.pop(context);
      await _addSelectedIngredients(selectedModified);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final selectedCount = selectedItems.values.where((v) => v).length;

          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_basket, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ingredients from Meal Plan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$selectedCount of ${ingredients.length} selected',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Ingredient List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = ingredients[index];
                        final currentIngredient = modifiedIngredients[ingredient]!;

                        // Use smart matching to find pantry item
                        final matchingPantryItem = IngredientMatcher.findMatchingPantryItem(
                          currentIngredient.name,
                          _pantryItems,
                        );

                        // Check quantity if pantry item found
                        final quantityCheck = IngredientMatcher.checkQuantity(
                          neededQuantity: currentIngredient.quantity,
                          neededUnit: currentIngredient.unit,
                          pantryItem: matchingPantryItem,
                        );

                        final existingGroceryItem = _groceryItems.firstWhere(
                          (item) => IngredientMatcher.normalizeIngredientName(item.name) ==
                                   IngredientMatcher.normalizeIngredientName(ingredient.name),
                          orElse: () => GroceryItem(
                            id: '',
                            name: '',
                            quantity: 0,
                            unit: '',
                            category: '',
                          ),
                        );
                        final isInGroceryList = existingGroceryItem.name.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: CheckboxListTile(
                            value: selectedItems[ingredient],
                            onChanged: (value) {
                              setState(() {
                                selectedItems[ingredient] = value ?? false;
                              });
                            },
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentIngredient.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  color: Theme.of(context).colorScheme.primary,
                                  onPressed: () {
                                    _showEditQuantityDialog(
                                      context,
                                      currentIngredient,
                                      (updated) {
                                        setState(() {
                                          modifiedIngredients[ingredient] = updated;
                                        });
                                      },
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${currentIngredient.quantity} ${currentIngredient.unit}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: ingredient.recipeNames.map((recipeName) {
                                    return Chip(
                                      label: Text(
                                        recipeName,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    );
                                  }).toList(),
                                ),
                                if (matchingPantryItem != null || isInGroceryList) ...[
                                  const SizedBox(height: 4),
                                  if (matchingPantryItem != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: quantityCheck['hasEnough'] == true
                                            ? Colors.green[100]
                                            : Colors.orange[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            quantityCheck['hasEnough'] == true
                                                ? Icons.check_circle
                                                : Icons.warning_amber,
                                            size: 14,
                                            color: quantityCheck['hasEnough'] == true
                                                ? Colors.green[800]
                                                : Colors.orange[800],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              quantityCheck['hasEnough'] == true
                                                  ? 'In pantry: ${quantityCheck['pantryQty']} ${matchingPantryItem.unit}'
                                                  : quantityCheck['unitMismatch'] == true
                                                      ? 'In pantry: ${quantityCheck['pantryQty']} ${quantityCheck['pantryUnit']} (Need ${quantityCheck['needed']} ${quantityCheck['neededUnit']})'
                                                      : 'In pantry: ${quantityCheck['pantryQty']} ${matchingPantryItem.unit} (Need ${quantityCheck['remaining']} more)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: quantityCheck['hasEnough'] == true
                                                    ? Colors.green[800]
                                                    : Colors.orange[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isInGroceryList)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      margin: EdgeInsets.only(top: matchingPantryItem != null ? 4 : 0),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.info, size: 14, color: Colors.blue[800]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Already in list: ${existingGroceryItem.quantity} ${existingGroceryItem.unit}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: selectedCount > 0 ? addIngredientsWithModifications : null,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: Text('Add $selectedCount Items'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditQuantityDialog(
    BuildContext context,
    ParsedIngredient ingredient,
    Function(ParsedIngredient) onUpdate,
  ) {
    final quantityController = TextEditingController(
      text: ingredient.quantity.toString(),
    );
    final unitController = TextEditingController(text: ingredient.unit);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${ingredient.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g., 2, 1.5',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: 'Unit',
                hintText: 'e.g., kg, L, pieces',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = double.tryParse(quantityController.text) ?? ingredient.quantity;
              final newUnit = unitController.text.isNotEmpty ? unitController.text : ingredient.unit;

              final updated = ingredient.copyWith(
                quantity: newQuantity,
                unit: newUnit,
              );

              onUpdate(updated);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSelectedIngredients(List<ParsedIngredient> selectedIngredients) async {
    try {
      // Convert to GroceryItem
      final newGroceryItems = selectedIngredients.map((ingredient) {
        return GroceryItem(
          id: _uuid.v4(),
          name: ingredient.name,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          category: ingredient.category,
        );
      }).toList();

      // Save to storage
      await _storage.insertGroceryItems(newGroceryItems);

      // Update UI
      setState(() {
        _groceryItems.addAll(newGroceryItems);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${newGroceryItems.length} items to your grocery list!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Group items by category
  Map<String, List<GroceryItem>> _groupByCategory() {
    final Map<String, List<GroceryItem>> grouped = {};
    for (var item in _groceryItems) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate from Meal Plan',
            onPressed: _generateFromMealPlan,
          ),
          if (_groceryItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear Purchased',
              onPressed: () async {
                setState(() {
                  _groceryItems.removeWhere((item) => item.isPurchased);
                });
                await _storage.deletePurchasedGroceryItems();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Purchased items cleared'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        heroTag: 'grocery_fab',
        child: const Icon(Icons.add),
      ),
      body: _groceryItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your grocery list is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items manually or tap the',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'icon to generate from your meal plan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedItems.keys.length,
              itemBuilder: (context, index) {
                final category = groupedItems.keys.elementAt(index);
                final items = groupedItems[category]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ...items.asMap().entries.map((entry) {
                        final itemIndex = _groceryItems.indexOf(entry.value);
                        final item = entry.value;
                        return CheckboxListTile(
                          value: item.isPurchased,
                          onChanged: (value) => _togglePurchased(itemIndex),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isPurchased
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isPurchased
                                  ? Colors.grey[600]
                                  : null,
                            ),
                          ),
                          subtitle: Text('${item.quantity} ${item.unit}'),
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final itemId = item.id;
                              setState(() {
                                _groceryItems.removeAt(itemIndex);
                              });
                              await _storage.deleteGroceryItem(itemId);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}