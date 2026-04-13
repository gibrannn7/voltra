class CategoryModel {
  final int id;
  final String name;
  final String icon;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'help',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  static List<CategoryModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
