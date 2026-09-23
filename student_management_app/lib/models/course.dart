class Course {
  final int id;
  final String name;
  final String description;
  final int durationMonths;
  final bool isActive;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMonths,
    required this.isActive,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      durationMonths: json['durationMonths'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'durationMonths': durationMonths,
      'isActive': isActive,
    };
  }
}
