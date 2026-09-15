class MealItem {
  final String id;
  final String name;
  final int calories;
  final int fatGrams;
  final int proteinGrams;
  final int carbGrams;
  final String imageUrl;

  const MealItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.fatGrams,
    required this.proteinGrams,
    required this.carbGrams,
    required this.imageUrl,
  });

  String get nutritionalSummary =>
      '$calories Calories, fat $fatGrams gm, protein $proteinGrams gm and carbohydrates $carbGrams gm';

  MealItem copyWith({
    String? id,
    String? name,
    int? calories,
    int? fatGrams,
    int? proteinGrams,
    int? carbGrams,
    String? imageUrl,
  }) {
    return MealItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      fatGrams: fatGrams ?? this.fatGrams,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbGrams: carbGrams ?? this.carbGrams,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
