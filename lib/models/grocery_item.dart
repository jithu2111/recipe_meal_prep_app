class GroceryItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String category; // Produce, Dairy, Grains, etc.
  final bool isPurchased;

  GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isPurchased = false,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      category: json['category'] as String,
      isPurchased: json['isPurchased'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'isPurchased': isPurchased,
    };
  }

  GroceryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    bool? isPurchased,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}