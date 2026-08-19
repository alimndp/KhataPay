class Category {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final bool isDefault;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.isDefault = false,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }
}