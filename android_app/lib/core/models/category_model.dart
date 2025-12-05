class CategoryModel {
  final int id;
  final String name;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
    };
  }
}
