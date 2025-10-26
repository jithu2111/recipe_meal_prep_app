import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FilterPanel extends StatelessWidget {
  final List<String> selectedDietaryTags;
  final String? selectedCuisine;
  final String? selectedCookingTime;
  final Function(String) onDietaryTagToggle;
  final Function(String?) onCuisineChanged;
  final Function(String?) onCookingTimeChanged;
  final VoidCallback onClearFilters;

  const FilterPanel({
    super.key,
    required this.selectedDietaryTags,
    required this.selectedCuisine,
    required this.selectedCookingTime,
    required this.onDietaryTagToggle,
    required this.onCuisineChanged,
    required this.onCookingTimeChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dietary Preferences
          _buildSectionTitle(context, 'Dietary Preferences'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Constants.dietaryTags.map((tag) {
              final isSelected = selectedDietaryTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (_) => onDietaryTagToggle(tag),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Cuisine Type
          _buildSectionTitle(context, 'Cuisine Type'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedCuisine,
            decoration: InputDecoration(
              hintText: 'Select cuisine',
              prefixIcon: const Icon(Icons.public),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Cuisines'),
              ),
              ...Constants.cuisineTypes.map((cuisine) {
                return DropdownMenuItem<String>(
                  value: cuisine,
                  child: Text(cuisine),
                );
              }),
            ],
            onChanged: onCuisineChanged,
          ),
          const SizedBox(height: 16),

          // Cooking Time
          _buildSectionTitle(context, 'Cooking Time'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedCookingTime,
            decoration: InputDecoration(
              hintText: 'Select cooking time',
              prefixIcon: const Icon(Icons.access_time),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Any Duration'),
              ),
              ...Constants.cookingTimeFilters.map((time) {
                return DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                );
              }),
            ],
            onChanged: onCookingTimeChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}