import '../models/pantry_item.dart';

class IngredientMatcher {
  /// Normalizes an ingredient name for better matching
  /// Removes common descriptions, converts to lowercase, handles plurals
  static String normalizeIngredientName(String name) {
    String normalized = name.toLowerCase().trim();

    // Remove common descriptors and preparation methods
    final descriptors = [
      ', sliced',
      ', diced',
      ', chopped',
      ', minced',
      ', grated',
      ', julienned',
      ', roasted',
      ', cooked',
      ', fresh',
      ', frozen',
      ', canned',
      ', dried',
      'for serving',
      'for garnish',
      'to taste',
      'optional',
    ];

    for (var descriptor in descriptors) {
      normalized = normalized.replaceAll(descriptor, '');
    }

    // Remove extra whitespace
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Handle common plurals (simple approach)
    if (normalized.endsWith('ies')) {
      // berries -> berry, cherries -> cherry
      normalized = normalized.substring(0, normalized.length - 3) + 'y';
    } else if (normalized.endsWith('ves')) {
      // knives -> knife, halves -> half
      normalized = normalized.substring(0, normalized.length - 3) + 'f';
    } else if (normalized.endsWith('ses')) {
      // glasses -> glass
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.endsWith('s') && !normalized.endsWith('ss')) {
      // Remove trailing 's' for simple plurals
      // but keep words ending in 'ss' like 'grass'
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// Finds a matching pantry item for the given ingredient name
  /// Returns the pantry item if found, null otherwise
  static PantryItem? findMatchingPantryItem(
    String ingredientName,
    List<PantryItem> pantryItems,
  ) {
    final normalizedIngredient = normalizeIngredientName(ingredientName);

    for (var pantryItem in pantryItems) {
      final normalizedPantry = normalizeIngredientName(pantryItem.name);

      // Exact match after normalization
      if (normalizedPantry == normalizedIngredient) {
        return pantryItem;
      }

      // Contains match (for partial matches)
      if (normalizedPantry.contains(normalizedIngredient) ||
          normalizedIngredient.contains(normalizedPantry)) {
        // Only match if they share significant words
        final pantryWords = normalizedPantry.split(' ');
        final ingredientWords = normalizedIngredient.split(' ');

        // Check if at least one significant word matches
        final hasCommonWord = pantryWords.any(
          (word) => word.length > 3 && ingredientWords.contains(word),
        );

        if (hasCommonWord) {
          return pantryItem;
        }
      }
    }

    return null;
  }

  /// Checks if there's enough quantity in pantry for the needed amount
  /// Returns: { hasEnough: bool, pantryQty: double, needed: double }
  static Map<String, dynamic> checkQuantity({
    required double neededQuantity,
    required String neededUnit,
    PantryItem? pantryItem,
  }) {
    if (pantryItem == null) {
      return {
        'hasEnough': false,
        'pantryQty': 0.0,
        'needed': neededQuantity,
        'remaining': neededQuantity,
      };
    }

    // Normalize units for comparison
    final normalizedNeededUnit = _normalizeUnit(neededUnit);
    final normalizedPantryUnit = _normalizeUnit(pantryItem.unit);

    // If units don't match, we can't compare quantities accurately
    // In this case, we assume user needs to add the full amount
    if (normalizedNeededUnit != normalizedPantryUnit) {
      return {
        'hasEnough': false,
        'pantryQty': pantryItem.quantity,
        'pantryUnit': pantryItem.unit,
        'needed': neededQuantity,
        'neededUnit': neededUnit,
        'remaining': neededQuantity,
        'unitMismatch': true,
      };
    }

    // Units match, compare quantities
    final hasEnough = pantryItem.quantity >= neededQuantity;
    final remaining = hasEnough ? 0.0 : neededQuantity - pantryItem.quantity;

    return {
      'hasEnough': hasEnough,
      'pantryQty': pantryItem.quantity,
      'needed': neededQuantity,
      'remaining': remaining,
      'unitMismatch': false,
    };
  }

  /// Normalizes unit names for comparison
  static String _normalizeUnit(String unit) {
    final normalized = unit.toLowerCase().trim();

    // Map similar units together
    final unitMap = {
      'piece': 'piece',
      'pieces': 'piece',
      'item': 'piece',
      'items': 'piece',
      'whole': 'piece',
      'cup': 'cup',
      'cups': 'cup',
      'c': 'cup',
      'tbsp': 'tbsp',
      'tablespoon': 'tbsp',
      'tablespoons': 'tbsp',
      'tsp': 'tsp',
      'teaspoon': 'tsp',
      'teaspoons': 'tsp',
      'g': 'g',
      'gram': 'g',
      'grams': 'g',
      'kg': 'kg',
      'kilogram': 'kg',
      'kilograms': 'kg',
      'ml': 'ml',
      'milliliter': 'ml',
      'milliliters': 'ml',
      'l': 'l',
      'liter': 'l',
      'liters': 'l',
      'oz': 'oz',
      'ounce': 'oz',
      'ounces': 'oz',
      'lb': 'lb',
      'pound': 'lb',
      'pounds': 'lb',
    };

    return unitMap[normalized] ?? normalized;
  }
}