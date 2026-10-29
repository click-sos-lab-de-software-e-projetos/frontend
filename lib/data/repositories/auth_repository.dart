import 'package:dio/dio.dart';

import '../models/user_profile.dart';
import 'repository_exception.dart';

abstract interface class AuthRepository {
  /// Returns the logged-in user's profile. Throws [InvalidCredentialsException]
  /// for wrong credentials and [RepositoryException] for other failures.
  Future<UserProfile> login({required String email, required String password});
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<UserProfile> login({required String email, required String password}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/auth/login', data: {'email': email, 'password': password});
      final profile = UserProfile.fromJson(r.data ?? const {});
      return profile.email.isEmpty ? profile.copyWith(email: email) : profile;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) throw InvalidCredentialsException(cause: e);
      throw RepositoryException('Não foi possível entrar. Verifique sua conexão.', cause: e);
    }
  }
}

/// Accepts any non-empty e-mail and password.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.profile = demoProfile});

  static const demoProfile = UserProfile(
    name: 'Usuário Demonstração',
    email: 'demo@alertaseguro.app',
    phone: '+55 (11) 90000-0000',
    protectionId: '#AS-00001',
  );

  final UserProfile profile;

  @override
  Future<UserProfile> login({required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) throw const InvalidCredentialsException();
    return profile.copyWith(email: email.trim());
  }
}
