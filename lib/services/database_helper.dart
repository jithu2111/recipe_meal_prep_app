import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/meal_plan.dart';
import '../models/pantry_item.dart';
import '../models/grocery_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'recipe_meal_prep.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        recipe_id TEXT PRIMARY KEY
      )
    ''');

    // Meal Plans table
    await db.execute('''
      CREATE TABLE meal_plans (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        recipe_id TEXT NOT NULL
      )
    ''');

    // Pantry Items table
    await db.execute('''
      CREATE TABLE pantry_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        expiration_date TEXT
      )
    ''');

    // Grocery List table
    await db.execute('''
      CREATE TABLE grocery_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        category TEXT NOT NULL,
        is_purchased INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ==================== FAVORITES ====================

  Future<void> addFavorite(String recipeId) async {
    final db = await database;
    await db.insert(
      'favorites',
      {'recipe_id': recipeId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(String recipeId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
  }

  Future<Set<String>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return maps.map((map) => map['recipe_id'] as String).toSet();
  }

  // ==================== MEAL PLANS ====================

  Future<void> insertMealPlan(MealPlan mealPlan) async {
    final db = await database;
    await db.insert(
      'meal_plans',
      {
        'id': mealPlan.id,
        'date': mealPlan.date.toIso8601String(),
        'meal_type': mealPlan.mealType.toString().split('.').last,
        'recipe_id': mealPlan.recipeId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMealPlan(String id) async {
    final db = await database;
    await db.delete(
      'meal_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMealPlanByDateAndType(DateTime date, MealType mealType) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0]; // Get date part only
    final mealTypeStr = mealType.toString().split('.').last;

    await db.delete(
      'meal_plans',
      where: 'date LIKE ? AND meal_type = ?',
      whereArgs: ['$dateStr%', mealTypeStr],
    );
  }

  Future<List<MealPlan>> getMealPlans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('meal_plans');

    return maps.map((map) {
      MealType mealType;
      switch (map['meal_type']) {
        case 'breakfast':
          mealType = MealType.breakfast;
          break;
        case 'lunch':
          mealType = MealType.lunch;
          break;
        case 'dinner':
          mealType = MealType.dinner;
          break;
        default:
          mealType = MealType.breakfast;
      }

      return MealPlan(
        id: map['id'],
        date: DateTime.parse(map['date']),
        mealType: mealType,
        recipeId: map['recipe_id'],
      );
    }).toList();
  }

  // ==================== PANTRY ITEMS ====================

  Future<void> insertPantryItem(PantryItem item) async {
    final db = await database;
    await db.insert(
      'pantry_items',
      {
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'expiration_date': item.expirationDate?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePantryItem(PantryItem item) async {
    final db = await database;
    await db.update(
      'pantry_items',
      {
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'expiration_date': item.expirationDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deletePantryItem(String id) async {
    final db = await database;
    await db.delete(
      'pantry_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PantryItem>> getPantryItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pantry_items');

    return maps.map((map) => PantryItem(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      unit: map['unit'],
      expirationDate: map['expiration_date'] != null
          ? DateTime.parse(map['expiration_date'])
          : null,
    )).toList();
  }

  // ==================== GROCERY ITEMS ====================

  Future<void> insertGroceryItem(GroceryItem item) async {
    final db = await database;
    await db.insert(
      'grocery_items',
      {
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'category': item.category,
        'is_purchased': item.isPurchased ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGroceryItem(GroceryItem item) async {
    final db = await database;
    await db.update(
      'grocery_items',
      {
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'category': item.category,
        'is_purchased': item.isPurchased ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteGroceryItem(String id) async {
    final db = await database;
    await db.delete(
      'grocery_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePurchasedGroceryItems() async {
    final db = await database;
    await db.delete(
      'grocery_items',
      where: 'is_purchased = ?',
      whereArgs: [1],
    );
  }

  Future<List<GroceryItem>> getGroceryItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('grocery_items');

    return maps.map((map) => GroceryItem(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      unit: map['unit'],
      category: map['category'],
      isPurchased: map['is_purchased'] == 1,
    )).toList();
  }

  // ==================== UTILITY ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('favorites');
    await db.delete('meal_plans');
    await db.delete('pantry_items');
    await db.delete('grocery_items');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}