class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isActive,
    this.salaryDay = 1,
  });

  final int id;
  final String email;
  final String name;
  final bool isActive;
  final int salaryDay;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        isActive: json['is_active'] as bool,
        salaryDay: (json['salary_day'] as int?) ?? 1,
      );

  AuthUser copyWith({int? salaryDay}) => AuthUser(
        id: id,
        email: email,
        name: name,
        isActive: isActive,
        salaryDay: salaryDay ?? this.salaryDay,
      );
}

sealed class AuthState {
  const AuthState();
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateAuthenticating extends AuthState {
  const AuthStateAuthenticating();
}

class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated(this.user, {this.needsOnboarding = false});
  final AuthUser user;
  final bool needsOnboarding;
}
