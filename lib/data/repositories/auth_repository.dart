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

  /// Saves the account's SOS message (empty clears it) and returns the updated profile.
  Future<UserProfile> updateSosMessage(String message);

  /// Saves only the given fields (phone in E.164) and returns the updated profile.
  Future<UserProfile> updateProfile({String? name, String? phone});

  /// Throws [WrongPasswordException] when [current] is not the account's password.
  Future<void> changePassword({required String current, required String next});

  /// Deletes the account for good; the server anonymizes its alerts.
  Future<void> deleteAccount(String password);
}

class EmailInUseException extends RepositoryException {
  const EmailInUseException({super.cause}) : super('Este e-mail já está cadastrado.');
}

class WrongPasswordException extends RepositoryException {
  const WrongPasswordException({super.cause}) : super('Senha atual incorreta.');
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

  @override
  Future<UserProfile> updateSosMessage(String message) async {
    try {
      final r = await _dio.patch<Map<String, dynamic>>('/auth/me', data: {'mensagem_sos': message});
      return UserProfile.fromApi(r.data ?? const {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw RepositoryException('A mensagem pode ter até 255 caracteres.', cause: e);
      }
      throw RepositoryException.fromDio(e, 'Não foi possível salvar a mensagem.');
    }
  }

  @override
  Future<UserProfile> updateProfile({String? name, String? phone}) async {
    try {
      final r = await _dio.patch<Map<String, dynamic>>(
        '/auth/me',
        data: {
          if (name != null) 'nome_completo': name,
          if (phone != null) 'telefone_pessoal': phone,
        },
      );
      return UserProfile.fromApi(r.data ?? const {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw RepositoryException('Confira o nome e o telefone (formato +55...).', cause: e);
      }
      throw RepositoryException.fromDio(e, 'Não foi possível salvar o perfil.');
    }
  }

  @override
  Future<void> changePassword({required String current, required String next}) async {
    try {
      await _dio.post<void>('/auth/me/senha', data: {'senha_atual': current, 'senha_nova': next});
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) throw WrongPasswordException(cause: e);
      if (e.response?.statusCode == 422) {
        throw RepositoryException('A senha nova precisa de ao menos 8 caracteres.', cause: e);
      }
      throw RepositoryException.fromDio(e, 'Não foi possível trocar a senha.');
    }
  }

  @override
  Future<void> deleteAccount(String password) async {
    try {
      await _dio.delete<void>('/auth/me', data: {'senha': password});
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) throw RepositoryException('Senha incorreta.', cause: e);
      throw RepositoryException.fromDio(e, 'Não foi possível excluir a conta.');
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
  final Map<String, String> _messages = {};
  final Map<String, UserProfile> _edited = {};
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
    final found = _edited[key] ?? _accounts[key]?.profile ?? profile.copyWith(email: key);
    return found.copyWith(sosMessage: _messages[key] ?? found.sosMessage);
  }

  @override
  Future<UserProfile> updateSosMessage(String message) async {
    final key = _current;
    if (key == null) throw const UnauthorizedException();
    _messages[key] = message;
    return me();
  }

  @override
  Future<UserProfile> updateProfile({String? name, String? phone}) async {
    final key = _current;
    if (key == null) throw const UnauthorizedException();
    final current = await me();
    _edited[key] = current.copyWith(name: name, phone: phone);
    return me();
  }

  /// Accounts created with [register] check [current]; demo accounts accept any.
  @override
  Future<void> changePassword({required String current, required String next}) async {
    final key = _current;
    if (key == null) throw const UnauthorizedException();
    final account = _accounts[key];
    if (account == null) return;
    if (account.password != current) throw const WrongPasswordException();
    _accounts[key] = (profile: account.profile, password: next);
  }

  /// Accounts created with [register] check [password]; demo accounts accept any.
  @override
  Future<void> deleteAccount(String password) async {
    final key = _current;
    if (key == null) throw const UnauthorizedException();
    final account = _accounts[key];
    if (account != null && account.password != password) throw const RepositoryException('Senha incorreta.');
    _accounts.remove(key);
    _edited.remove(key);
    _messages.remove(key);
    _current = null;
  }
}
