class AdminModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map, String id) {
    return AdminModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'admin',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}