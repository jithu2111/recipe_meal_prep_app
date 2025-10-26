import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pantry_item.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final List<PantryItem> _pantryItems = [];
  final _uuid = const Uuid();

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
              onPressed: () {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Pantry'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.quantity} ${item.unit}'),
                        if (item.expirationDate != null)
                          Text(
                            'Expires: ${item.expirationDate!.day}/${item.expirationDate!.month}/${item.expirationDate!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.expirationDate!.isBefore(DateTime.now())
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _pantryItems.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}