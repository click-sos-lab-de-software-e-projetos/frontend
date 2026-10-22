/// Raised by repositories when a request fails. [message] is user-facing (pt-BR).
class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'RepositoryException: $message';
}

class InvalidCredentialsException extends RepositoryException {
  const InvalidCredentialsException({super.cause}) : super('Credenciais inválidas.');
}
