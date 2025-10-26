# Recipe & Meal Planning App

A Flutter mobile application that helps users browse recipes, filter based on dietary preferences, plan weekly meals, and generate grocery lists automatically.

## Project Structure

```
lib/
├── data/              # Sample data and mock recipes
├── models/            # Data models (Recipe, MealPlan, PantryItem, GroceryItem)
├── providers/         # State management (Provider)
├── screens/           # UI screens
├── services/          # Business logic and API services
├── utils/             # Theme, constants, and utilities
├── widgets/           # Reusable widgets
└── main.dart          # App entry point
```

## Features

### Core Features
- **Recipe Browsing**: View recipes with images, ratings, and cooking times
- **Filtering**: Filter by dietary preferences, cuisine type, and cooking time
- **Recipe Details**: View ingredients, steps, cooking time, and nutrition facts
- **Meal Planning**: Weekly calendar to assign recipes to meals
- **Grocery List**: Automatically generated from meal plans
- **Favorites**: Save favorite recipes for quick access
- **Share Recipes**: Share recipes via social media or messaging

### Bonus Features
- **Smart Pantry Tracker**: Track available ingredients and highlight "Cook Now" recipes
- **Offline Mode**: Local storage for offline access
- **Dark Mode**: Support for dark theme

## Dependencies

```yaml
dependencies:
  provider: ^6.1.1              # State management
  shared_preferences: ^2.2.2    # Local storage
  http: ^1.2.0                  # HTTP requests
  share_plus: ^7.2.1            # Share functionality
  cached_network_image: ^3.3.1  # Image caching
  intl: ^0.19.0                 # Date/time formatting
  uuid: ^4.3.3                  # Unique IDs
```

## Getting Started

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Development Milestones

### Milestone 1
- [x] Set up project structure and dependencies
- [ ] Design and build recipe list UI
- [ ] Implement filter functionality
- [ ] Create recipe detail screen
- [ ] Add navigation

### Milestone 2
- [ ] Implement meal planner
- [ ] Add grocery list generation
- [ ] Integrate local storage
- [ ] Implement Smart Pantry Tracker
- [ ] Add share recipe functionality
- [ ] UI polish and testing

## Models

### Recipe
- ID, title, image URL
- Ingredients, steps
- Cooking time, rating
- Cuisine type, dietary tags
- Nutrition facts

### MealPlan
- ID, date, meal type
- Recipe reference

### PantryItem
- ID, name, quantity, unit
- Expiration date

### GroceryItem
- ID, name, quantity, unit
- Category, purchase status

## Contributing

This is a group project. Please follow the branching strategy:
- `main`: Production-ready code
- `develop`: Integration branch
- `feature/*`: Feature branches

## License

This project is for educational purposes.