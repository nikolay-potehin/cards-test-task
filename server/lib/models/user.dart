import 'package:server/core/constants.dart';
import 'package:server/core/data_class.dart';

/// {@template user}
/// Immutable user account record represented by [User].
/// {@endtemplate}
class User extends DataClass<User> {
  /// {@macro user}
  const User({
    required super.json,
    required this.id,
    required this.name,
    required this.email,
  });

  /// Creates a [User] from serialized data.
  factory User.fromJson(Map<String, Object?> json) {
    return User(
      json: json,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String email;

  @override
  List<Object?> get props => [id, name, email];

  /// Returns a new [User] with selected fields replaced.
  @override
  User copyWith({
    Defaulted<String> id = const Omit(),
    Defaulted<String> name = const Omit(),
    Defaulted<String> email = const Omit(),
  }) {
    return User(
      json: json,
      id: id is Omit ? this.id : id as String,
      name: name is Omit ? this.name : name as String,
      email: email is Omit ? this.email : email as String,
    );
  }

  /// Converts this [User] to serialized data.
  @override
  Map<String, Object> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}
