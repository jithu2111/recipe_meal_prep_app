import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/grocery_item.dart';
import '../models/pantry_item.dart';
import '../utils/constants.dart';

class GroceryListScreen extends StatefulWidget {
  final List<PantryItem> pantryItems;

  const GroceryListScreen({
    super.key,
    this.pantryItems = const [],
  });

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final List<GroceryItem> _groceryItems = [];
  final _uuid = const Uuid();

  // Check if an item is already in pantry
  bool _isInPantry(String itemName) {
    return widget.pantryItems.any(
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
              onPressed: () {
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

  void _togglePurchased(int index) {
    setState(() {
      _groceryItems[index] = _groceryItems[index].copyWith(
        isPurchased: !_groceryItems[index].isPurchased,
      );
    });
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
          if (_groceryItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear Purchased',
              onPressed: () {
                setState(() {
                  _groceryItems.removeWhere((item) => item.isPurchased);
                });
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
                    'Add items you need to buy!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
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
                            onPressed: () {
                              setState(() {
                                _groceryItems.removeAt(itemIndex);
                              });
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