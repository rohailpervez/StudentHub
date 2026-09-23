class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final int organizationId;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.organizationId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      organizationId: json['organizationId'] ?? 0,
    );
  }

  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    int? organizationId,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}
