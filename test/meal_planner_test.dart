import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_meal_prep_app/models/meal_plan.dart';
import 'package:recipe_meal_prep_app/data/sample_recipes.dart';

void main() {
  group('Meal Assignment Tests', () {
    test('Assign recipe to meal slot', () {
      final recipes = SampleRecipes.getRecipes();
      final recipe = recipes.first;

      final mealPlan = MealPlan(
        id: '1',
        date: DateTime.now(),
        mealType: MealType.breakfast,
        recipeId: recipe.id,
      );

      expect(mealPlan.recipeId, recipe.id);
      expect(mealPlan.mealType, MealType.breakfast);
    });

    test('Convert meal plan to JSON', () {
      final date = DateTime.now();
      final mealPlan = MealPlan(
        id: '1',
        date: date,
        mealType: MealType.lunch,
        recipeId: 'recipe-123',
      );

      final json = mealPlan.toJson();

      expect(json['id'], '1');
      expect(json['recipeId'], 'recipe-123');
      expect(json['mealType'], 'lunch');
    });

    test('Convert JSON to meal plan', () {
      final json = {
        'id': '2',
        'date': DateTime.now().toIso8601String(),
        'mealType': 'dinner',
        'recipeId': 'recipe-456',
      };

      final mealPlan = MealPlan.fromJson(json);

      expect(mealPlan.id, '2');
      expect(mealPlan.mealType, MealType.dinner);
      expect(mealPlan.recipeId, 'recipe-456');
    });
  });
}