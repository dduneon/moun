import 'package:mocktail/mocktail.dart';
import 'package:moun/features/auth/data/auth_repository.dart';
import 'package:moun/features/auth/domain/auth_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const kTestUser = AuthUser(
  id: 1,
  email: 'test@example.com',
  name: '테스터',
  isActive: true,
);

const kTokens = (
  accessToken: 'access_abc',
  refreshToken: 'refresh_xyz',
);
