/// Represents an authenticated user.
class UserModel {
  final int id;
  final String name;
  final String email;
  final String createdAt;
  final String? lastLogin;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      lastLogin: map['last_login']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'created_at': createdAt,
        'last_login': lastLogin,
      };
}
