import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pantry_item.dart';
import '../services/storage_service.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final List<PantryItem> _pantryItems = [];
  final _uuid = const Uuid();
  final _storage = StorageService();
  static const double _lowStockThreshold = 2.0; // Threshold for low stock alerts

  @override
  void initState() {
    super.initState();
    _loadPantryItems();
  }

  Future<void> _loadPantryItems() async {
    final items = await _storage.getPantryItems();
    setState(() {
      _pantryItems.addAll(items);
    });
  }


  // Check if item is low in stock
  bool _isLowStock(PantryItem item) {
    return item.quantity <= _lowStockThreshold;
  }

  // Get count of low stock items
  int _getLowStockCount() {
    return _pantryItems.where((item) => _isLowStock(item)).length;
  }

  Future<void> _askAI() async {
    if (_pantryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some ingredients to your pantry first!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Asking AI for recipe suggestions...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Prepare ingredients data
      final ingredients = _pantryItems.map((item) {
        return {
          'name': item.name,
          'quantity': '${item.quantity} ${item.unit}',
        };
      }).toList();

      // Send request to AI API
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/generate-recipe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ingredients': ingredients}),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showAIResponseDialog(
          data['message'] ?? 'No message received',
          data['can_make_recipe'] ?? false,
          data['suggestions'],
        );
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAIResponseDialog(String message, bool canMakeRecipe, String? suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              canMakeRecipe ? Icons.check_circle : Icons.info,
              color: canMakeRecipe ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                canMakeRecipe ? 'Recipe Suggestion' : 'Need More Ingredients',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              if (suggestions != null && suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Suggestions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  suggestions,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    DateTime? expirationDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Ingredient'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ingredient Name',
                    hintText: 'e.g., Eggs, Milk, Rice',
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expirationDate == null
                            ? 'No expiration date'
                            : 'Expires: ${expirationDate!.day}/${expirationDate!.month}/${expirationDate!.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            expirationDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Pick Date'),
                    ),
                  ],
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
                  final newItem = PantryItem(
                    id: _uuid.v4(),
                    name: nameController.text,
                    quantity: double.tryParse(quantityController.text) ?? 0,
                    unit: unitController.text,
                    expirationDate: expirationDate,
                  );
                  this.setState(() {
                    _pantryItems.add(newItem);
                  });
                  await _storage.insertPantryItem(newItem);
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

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _getLowStockCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Pantry'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          if (lowStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$lowStockCount Low',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _askAI,
            heroTag: 'ask_ai_fab',
            label: const Text('Ask AI'),
            icon: const Icon(Icons.psychology),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _showAddItemDialog,
            heroTag: 'pantry_fab',
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: _pantryItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.kitchen_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your pantry is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add ingredients you have at home!',
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
              itemCount: _pantryItems.length,
              itemBuilder: (context, index) {
                final item = _pantryItems[index];
                final isLowStock = _isLowStock(item);
                final isExpired = item.expirationDate != null &&
                    item.expirationDate!.isBefore(DateTime.now());

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isLowStock
                      ? Colors.orange[50]
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isLowStock
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        isLowStock
                            ? Icons.warning_amber
                            : Icons.inventory_2_outlined,
                        color: isLowStock
                            ? Colors.white
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(item.name)),
                        if (isLowStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Low Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity} ${item.unit}',
                          style: TextStyle(
                            color: isLowStock ? Colors.orange[900] : null,
                            fontWeight: isLowStock ? FontWeight.w600 : null,
                          ),
                        ),
                        if (item.expirationDate != null)
                          Text(
                            'Expires: ${item.expirationDate!.day}/${item.expirationDate!.month}/${item.expirationDate!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final itemId = item.id;
                        setState(() {
                          _pantryItems.removeAt(index);
                        });
                        await _storage.deletePantryItem(itemId);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}