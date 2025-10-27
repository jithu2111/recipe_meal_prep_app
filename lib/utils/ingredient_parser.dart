class IngredientParser {
  /// Converts fraction strings like "1/2" to decimal
  static double _parseFraction(String quantityStr) {
    if (quantityStr.contains('/')) {
      final parts = quantityStr.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts[0]) ?? 1.0;
        final denominator = double.tryParse(parts[1]) ?? 1.0;
        return numerator / denominator;
      }
    }
    return double.tryParse(quantityStr) ?? 1.0;
  }

  /// Parses an ingredient string (e.g., "2 cups flour") into a GroceryItem
  static ParsedIngredient parseIngredient(String ingredientString) {
    // Clean up the input
    final cleaned = ingredientString.trim();

    // Regular expression to match quantity, unit, and name
    // Patterns like: "2 cups flour", "1.5 kg chicken", "200g rice", "3 tbsp olive oil", "1/2 cup sugar"
    final regexPatterns = [
      // Pattern 1: "2 cups flour" or "1.5 kg chicken" (with fractions like 1/2)
      RegExp(r'^(\d+(?:\.\d+)?(?:/\d+)?)\s*([a-zA-Z]+)\s+(.+)$'),
      // Pattern 2: "200g rice" (no space between number and unit)
      RegExp(r'^(\d+(?:\.\d+)?(?:/\d+)?)([a-zA-Z]+)\s+(.+)$'),
      // Pattern 3: Just quantity and name, no unit: "2 eggs" or "1/2 onion"
      RegExp(r'^(\d+(?:\.\d+)?(?:/\d+)?)\s+(.+)$'),
    ];

    for (var regex in regexPatterns) {
      final match = regex.firstMatch(cleaned);
      if (match != null) {
        if (match.groupCount == 2) {
          // Pattern 3: quantity and name only
          final quantity = _parseFraction(match.group(1)!);
          final name = match.group(2)!;
          return ParsedIngredient(
            name: name,
            quantity: quantity,
            unit: 'piece',
            category: _categorizeIngredient(name),
          );
        } else if (match.groupCount == 3) {
          // Pattern 1 or 2: quantity, unit, and name
          final quantity = _parseFraction(match.group(1)!);
          final unit = _normalizeUnit(match.group(2)!);
          final name = match.group(3)!;
          return ParsedIngredient(
            name: name,
            quantity: quantity,
            unit: unit,
            category: _categorizeIngredient(name),
          );
        }
      }
    }

    // If no pattern matches, return the whole string as the name with quantity 1
    return ParsedIngredient(
      name: cleaned,
      quantity: 1.0,
      unit: 'item',
      category: _categorizeIngredient(cleaned),
    );
  }

  /// Normalizes common unit abbreviations
  static String _normalizeUnit(String unit) {
    final lowerUnit = unit.toLowerCase();

    // Map of abbreviations to full names
    final unitMap = {
      'tsp': 'tsp',
      'tbsp': 'tbsp',
      'cup': 'cup',
      'cups': 'cup',
      'oz': 'oz',
      'lb': 'lb',
      'lbs': 'lb',
      'g': 'g',
      'kg': 'kg',
      'ml': 'ml',
      'l': 'L',
      'clove': 'clove',
      'cloves': 'clove',
      'piece': 'piece',
      'pieces': 'piece',
      'slice': 'slice',
      'slices': 'slice',
    };

    return unitMap[lowerUnit] ?? lowerUnit;
  }

  /// Categorizes an ingredient based on common keywords
  static String _categorizeIngredient(String name) {
    final lowerName = name.toLowerCase();

    // Produce
    if (_containsAny(lowerName, [
      'tomato', 'lettuce', 'spinach', 'kale', 'carrot', 'onion', 'garlic',
      'potato', 'broccoli', 'pepper', 'cucumber', 'avocado', 'basil', 'cilantro',
      'parsley', 'celery', 'mushroom', 'zucchini', 'eggplant', 'squash',
      'cabbage', 'peas', 'beans', 'corn', 'greens', 'fruit', 'apple', 'banana',
      'berry', 'lemon', 'lime', 'orange', 'ginger', 'bamboo shoots', 'lime leaves'
    ])) {
      return 'Produce';
    }

    // Dairy
    if (_containsAny(lowerName, [
      'milk', 'cheese', 'butter', 'cream', 'yogurt', 'mozzarella', 'parmesan',
      'cheddar', 'feta', 'ricotta', 'sour cream', 'whipped cream'
    ])) {
      return 'Dairy';
    }

    // Meat & Seafood
    if (_containsAny(lowerName, [
      'chicken', 'beef', 'pork', 'turkey', 'lamb', 'fish', 'salmon', 'tuna',
      'shrimp', 'seafood', 'meat', 'bacon', 'sausage', 'ham'
    ])) {
      return 'Meat & Seafood';
    }

    // Grains & Pasta
    if (_containsAny(lowerName, [
      'flour', 'bread', 'rice', 'pasta', 'noodle', 'quinoa', 'oats', 'cereal',
      'tortilla', 'bagel', 'bun', 'roll', 'grain', 'wheat', 'barley'
    ])) {
      return 'Grains & Pasta';
    }

    // Canned & Jarred
    if (_containsAny(lowerName, [
      'sauce', 'canned', 'jarred', 'paste', 'tomato sauce', 'stock', 'broth',
      'coconut milk', 'chickpeas', 'hummus'
    ])) {
      return 'Canned & Jarred';
    }

    // Spices & Condiments
    if (_containsAny(lowerName, [
      'salt', 'pepper', 'spice', 'oregano', 'thyme', 'rosemary', 'cumin',
      'paprika', 'cinnamon', 'nutmeg', 'curry', 'soy sauce', 'vinegar',
      'oil', 'olive oil', 'sesame oil', 'honey', 'sugar', 'yeast', 'vanilla',
      'tahini', 'fish sauce', 'sesame seeds', 'red pepper flakes'
    ])) {
      return 'Spices & Condiments';
    }

    // Beverages
    if (_containsAny(lowerName, [
      'water', 'juice', 'soda', 'tea', 'coffee', 'wine', 'beer'
    ])) {
      return 'Beverages';
    }

    // Snacks
    if (_containsAny(lowerName, [
      'chip', 'cracker', 'cookie', 'candy', 'chocolate', 'nut', 'seed', 'granola'
    ])) {
      return 'Snacks';
    }

    // Default to Other
    return 'Other';
  }

  /// Helper function to check if a string contains any of the keywords
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Helper to extract base ingredient name (removes descriptors after commas)
  static String _extractBaseName(String name) {
    // Remove everything after comma (e.g., "cucumber, sliced" -> "cucumber")
    if (name.contains(',')) {
      return name.split(',')[0].trim();
    }
    return name.trim();
  }

  /// Merges duplicate ingredients by combining quantities
  static List<ParsedIngredient> mergeDuplicates(List<ParsedIngredient> ingredients) {
    final Map<String, ParsedIngredient> merged = {};

    for (var ingredient in ingredients) {
      // Extract base name without descriptors
      final baseName = _extractBaseName(ingredient.name);
      final key = '${baseName.toLowerCase()}_${ingredient.unit}';

      if (merged.containsKey(key)) {
        // Add quantities together and merge recipe names
        final existing = merged[key]!;
        final combinedRecipes = [...existing.recipeNames, ...ingredient.recipeNames];
        merged[key] = ParsedIngredient(
          name: baseName, // Use the cleaned base name
          quantity: existing.quantity + ingredient.quantity,
          unit: existing.unit,
          category: existing.category,
          recipeNames: combinedRecipes,
        );
      } else {
        // Store with cleaned base name
        merged[key] = ParsedIngredient(
          name: baseName,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          category: ingredient.category,
          recipeNames: ingredient.recipeNames,
        );
      }
    }

    return merged.values.toList();
  }
}

/// Class to hold parsed ingredient data
class ParsedIngredient {
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final List<String> recipeNames; // Track which recipes use this ingredient

  ParsedIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.recipeNames = const [],
  });

  ParsedIngredient copyWith({
    String? name,
    double? quantity,
    String? unit,
    String? category,
    List<String>? recipeNames,
  }) {
    return ParsedIngredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      recipeNames: recipeNames ?? this.recipeNames,
    );
  }

  @override
  String toString() {
    return '$quantity $unit $name ($category)';
  }
}
