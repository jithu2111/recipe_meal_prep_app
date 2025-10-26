class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> steps;
  final int cookingTime; // in minutes
  final double rating;
  final String cuisine;
  final List<String> dietaryTags; // vegetarian, vegan, gluten-free, etc.
  final String? nutritionFacts;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.cookingTime,
    required this.rating,
    required this.cuisine,
    required this.dietaryTags,
    this.nutritionFacts,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      ingredients: List<String>.from(json['ingredients'] as List),
      steps: List<String>.from(json['steps'] as List),
      cookingTime: json['cookingTime'] as int,
      rating: (json['rating'] as num).toDouble(),
      cuisine: json['cuisine'] as String,
      dietaryTags: List<String>.from(json['dietaryTags'] as List),
      nutritionFacts: json['nutritionFacts'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'steps': steps,
      'cookingTime': cookingTime,
      'rating': rating,
      'cuisine': cuisine,
      'dietaryTags': dietaryTags,
      'nutritionFacts': nutritionFacts,
    };
  }
}