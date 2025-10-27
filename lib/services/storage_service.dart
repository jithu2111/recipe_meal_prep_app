import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan.dart';
import '../models/pantry_item.dart';
import '../models/grocery_item.dart';
import '../utils/constants.dart';
import 'database_helper.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _dbHelper = DatabaseHelper();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Initialize database
    await _dbHelper.database;
  }

  // ==================== FAVORITES ====================

  Future<Set<String>> getFavorites() async {
    return await _dbHelper.getFavorites();
  }

  Future<void> addFavorite(String recipeId) async {
    await _dbHelper.addFavorite(recipeId);
  }

  Future<void> removeFavorite(String recipeId) async {
    await _dbHelper.removeFavorite(recipeId);
  }

  // ==================== MEAL PLANS ====================

  Future<List<MealPlan>> getMealPlans() async {
    return await _dbHelper.getMealPlans();
  }

  Future<void> insertMealPlan(MealPlan mealPlan) async {
    await _dbHelper.insertMealPlan(mealPlan);
  }

  Future<void> deleteMealPlan(String id) async {
    await _dbHelper.deleteMealPlan(id);
  }

  Future<void> deleteMealPlanByDateAndType(DateTime date, MealType mealType) async {
    await _dbHelper.deleteMealPlanByDateAndType(date, mealType);
  }

  // ==================== PANTRY ITEMS ====================

  Future<List<PantryItem>> getPantryItems() async {
    return await _dbHelper.getPantryItems();
  }

  Future<void> insertPantryItem(PantryItem item) async {
    await _dbHelper.insertPantryItem(item);
  }

  Future<void> updatePantryItem(PantryItem item) async {
    await _dbHelper.updatePantryItem(item);
  }

  Future<void> deletePantryItem(String id) async {
    await _dbHelper.deletePantryItem(id);
  }

  // ==================== GROCERY ITEMS ====================

  Future<List<GroceryItem>> getGroceryList() async {
    return await _dbHelper.getGroceryItems();
  }

  Future<void> insertGroceryItem(GroceryItem item) async {
    await _dbHelper.insertGroceryItem(item);
  }

  Future<void> updateGroceryItem(GroceryItem item) async {
    await _dbHelper.updateGroceryItem(item);
  }

  Future<void> deleteGroceryItem(String id) async {
    await _dbHelper.deleteGroceryItem(id);
  }

  Future<void> deletePurchasedGroceryItems() async {
    await _dbHelper.deletePurchasedGroceryItems();
  }

  Future<void> insertGroceryItems(List<GroceryItem> items) async {
    for (var item in items) {
      await _dbHelper.insertGroceryItem(item);
    }
  }

  // ==================== THEME (Still using SharedPreferences) ====================

  Future<String?> getThemeMode() async {
    return _prefs?.getString(Constants.themeKey);
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs?.setString(Constants.themeKey, mode);
  }

  // ==================== UTILITY ====================

  Future<void> clearAll() async {
    await _dbHelper.clearAllData();
    await _prefs?.clear();
  }
}