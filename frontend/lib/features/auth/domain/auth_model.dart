class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isActive,
  });

  final int id;
  final String email;
  final String name;
  final bool isActive;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        isActive: json['is_active'] as bool,
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
  const AuthStateAuthenticated(this.user);
  final AuthUser user;
}
