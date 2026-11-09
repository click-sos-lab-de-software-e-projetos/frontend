import 'package:dio/dio.dart';

/// Raised by repositories when a request fails. [message] is user-facing (pt-BR).
class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.cause});

  /// Uses the backend's `detail` message when it is a plain string (custom
  /// errors such as 409/422), otherwise [fallback].
  factory RepositoryException.fromDio(DioException e, String fallback) {
    final status = e.response?.statusCode;
    if (status == 401) return UnauthorizedException(cause: e);
    final data = e.response?.data;
    final detail = data is Map ? data['detail'] : null;
    return RepositoryException(detail is String && detail.isNotEmpty ? detail : fallback, cause: e);
  }

  final String message;
  final Object? cause;

  @override
  String toString() => 'RepositoryException: $message';
}

class InvalidCredentialsException extends RepositoryException {
  const InvalidCredentialsException({super.cause}) : super('E-mail ou senha inválidos.');
}

/// The request needed a valid session (missing or expired token).
class UnauthorizedException extends RepositoryException {
  const UnauthorizedException({super.cause}) : super('Sua sessão expirou. Entre novamente.');
}
