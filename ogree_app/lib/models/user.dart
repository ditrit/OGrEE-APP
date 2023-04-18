// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class User {
  String? id;
  String email;
  String password;
  Map<String, String> roles;

  User(
      {required this.email,
      required this.password,
      required this.roles,
      this.id});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'roles': roles,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
        id: map['_id'].toString(),
        email: map['email'].toString(),
        password: map['password'].toString(),
        roles: Map<String, String>.from(map['roles']));
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(id: $id, email: $email, password: $password, roles: $roles)';
  }
}
