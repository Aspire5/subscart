import '../../domain/entities/meal_item.dart';

class MealItemModel {
  final String id;
  final String name;
  final int calories;
  final int fatGrams;
  final int proteinGrams;
  final int carbGrams;
  final String imageUrl;

  const MealItemModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.fatGrams,
    required this.proteinGrams,
    required this.carbGrams,
    required this.imageUrl,
  });

  factory MealItemModel.fromJson(Map<String, dynamic> json) {
    return MealItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: json['calories'] as int,
      fatGrams: json['fatGrams'] as int,
      proteinGrams: json['proteinGrams'] as int,
      carbGrams: json['carbGrams'] as int,
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'fatGrams': fatGrams,
      'proteinGrams': proteinGrams,
      'carbGrams': carbGrams,
      'imageUrl': imageUrl,
    };
  }

  MealItem toEntity() {
    return MealItem(
      id: id,
      name: name,
      calories: calories,
      fatGrams: fatGrams,
      proteinGrams: proteinGrams,
      carbGrams: carbGrams,
      imageUrl: imageUrl,
    );
  }

  factory MealItemModel.fromEntity(MealItem entity) {
    return MealItemModel(
      id: entity.id,
      name: entity.name,
      calories: entity.calories,
      fatGrams: entity.fatGrams,
      proteinGrams: entity.proteinGrams,
      carbGrams: entity.carbGrams,
      imageUrl: entity.imageUrl,
    );
  }
}
