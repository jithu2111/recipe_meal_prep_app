import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../models/pantry_item.dart';
import '../models/grocery_item.dart';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Favorites
  Future<Set<String>> getFavorites() async {
    final favoritesJson = _prefs?.getStringList(Constants.favoritesKey) ?? [];
    return Set<String>.from(favoritesJson);
  }

  Future<void> saveFavorites(Set<String> favorites) async {
    await _prefs?.setStringList(
      Constants.favoritesKey,
      favorites.toList(),
    );
  }

  // Meal Plans
  Future<List<MealPlan>> getMealPlans() async {
    final mealPlansJson = _prefs?.getString(Constants.mealPlansKey);
    if (mealPlansJson == null || mealPlansJson.isEmpty) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(mealPlansJson);
    return decoded.map((json) => MealPlan.fromJson(json)).toList();
  }

  Future<void> saveMealPlans(List<MealPlan> mealPlans) async {
    final encoded = jsonEncode(
      mealPlans.map((plan) => plan.toJson()).toList(),
    );
    await _prefs?.setString(Constants.mealPlansKey, encoded);
  }

  // Pantry Items
  Future<List<PantryItem>> getPantryItems() async {
    final pantryJson = _prefs?.getString(Constants.pantryItemsKey);
    if (pantryJson == null || pantryJson.isEmpty) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(pantryJson);
    return decoded.map((json) => PantryItem.fromJson(json)).toList();
  }

  Future<void> savePantryItems(List<PantryItem> items) async {
    final encoded = jsonEncode(
      items.map((item) => item.toJson()).toList(),
    );
    await _prefs?.setString(Constants.pantryItemsKey, encoded);
  }

  // Grocery List
  Future<List<GroceryItem>> getGroceryList() async {
    final groceryJson = _prefs?.getString(Constants.groceryListKey);
    if (groceryJson == null || groceryJson.isEmpty) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(groceryJson);
    return decoded.map((json) => GroceryItem.fromJson(json)).toList();
  }

  Future<void> saveGroceryList(List<GroceryItem> items) async {
    final encoded = jsonEncode(
      items.map((item) => item.toJson()).toList(),
    );
    await _prefs?.setString(Constants.groceryListKey, encoded);
  }

  // Theme Mode
  Future<String?> getThemeMode() async {
    return _prefs?.getString(Constants.themeKey);
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs?.setString(Constants.themeKey, mode);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}