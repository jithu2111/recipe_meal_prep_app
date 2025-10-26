class MealPlan {
  final String id;
  final DateTime date;
  final MealType mealType;
  final String recipeId;

  MealPlan({
    required this.id,
    required this.date,
    required this.mealType,
    required this.recipeId,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mealType: MealType.values.firstWhere(
        (e) => e.toString() == 'MealType.${json['mealType']}',
      ),
      recipeId: json['recipeId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mealType': mealType.toString().split('.').last,
      'recipeId': recipeId,
    };
  }
}

enum MealType {
  breakfast,
  lunch,
  dinner,
}