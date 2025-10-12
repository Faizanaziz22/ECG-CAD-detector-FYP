import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
    );
  }

  factory User.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return User.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  bool get isPatient => role == 'patient';
  bool get isDoctor => role == 'doctor';

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, role: $role}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ email.hashCode ^ role.hashCode;
}