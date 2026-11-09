import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/user_profile.dart';
import 'repository_exception.dart';

abstract interface class AuthRepository {
  /// Returns the access token. Throws [InvalidCredentialsException] for wrong
  /// credentials and [RepositoryException] for other failures.
  Future<String> login({required String email, required String password});

  /// Creates the account (it does not log in). Throws [EmailInUseException]
  /// when the e-mail is taken.
  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Profile of the session's user. Throws [UnauthorizedException] without a valid session.
  Future<UserProfile> me();
}

class EmailInUseException extends RepositoryException {
  const EmailInUseException({super.cause}) : super('Este e-mail já está cadastrado.');
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<String> login({required String email, required String password}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'senha': password},
        options: AuthInterceptor.public,
      );
      final token = r.data?['access_token'];
      if (token is! String || token.isEmpty) throw const RepositoryException('Resposta inválida do servidor.');
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw InvalidCredentialsException(cause: e);
      throw RepositoryException.fromDio(e, 'Não foi possível entrar. Verifique sua conexão.');
    }
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/auth/cadastro',
        data: {'nome_completo': name, 'email': email, 'telefone_pessoal': phone, 'senha': password},
        options: AuthInterceptor.public,
      );
      return UserProfile.fromApi(r.data ?? const {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) throw EmailInUseException(cause: e);
      if (e.response?.statusCode == 422) {
        throw RepositoryException('Confira os dados: e-mail, telefone e senha (mín. 8 caracteres).', cause: e);
      }
      throw RepositoryException.fromDio(e, 'Não foi possível criar a conta. Verifique sua conexão.');
    }
  }

  @override
  Future<UserProfile> me() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/auth/me');
      return UserProfile.fromApi(r.data ?? const {});
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e, 'Não foi possível carregar seu perfil.');
    }
  }
}

/// In-memory accounts. Accepts any non-empty e-mail and password for
/// accounts it does not know (demo mode).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.profile = demoProfile});

  static const demoProfile = UserProfile(
    name: 'Usuário Demonstração',
    email: 'demo@alertaseguro.app',
    phone: '+5511900000000',
    protectionId: 'demo-usuario',
  );

  final UserProfile profile;
  final Map<String, ({UserProfile profile, String password})> _accounts = {};
  String? _current;

  @override
  Future<String> login({required String email, required String password}) async {
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (key.isEmpty || password.isEmpty || (account != null && account.password != password)) {
      throw const InvalidCredentialsException();
    }
    _current = key;
    return 'fake-token-$key';
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) throw const EmailInUseException();
    final created = UserProfile(name: name.trim(), email: key, phone: phone, protectionId: 'fake-${_accounts.length}');
    _accounts[key] = (profile: created, password: password);
    return created;
  }

  @override
  Future<UserProfile> me() async {
    final key = _current;
    if (key == null) throw const UnauthorizedException();
    return _accounts[key]?.profile ?? profile.copyWith(email: key);
  }
}
