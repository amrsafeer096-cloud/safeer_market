import '../l10n/l10n.dart';

sealed class Failure {
  const Failure(this.message);

  final String message;
}

class NetworkFailure extends Failure {
  NetworkFailure([String? message])
      : super(message ?? L10n.current.networkError);
}

class ServerFailure extends Failure {
  ServerFailure([String? message]) : super(message ?? L10n.current.serverError);
}

class UnexpectedFailure extends Failure {
  UnexpectedFailure([String? message])
      : super(message ?? L10n.current.unexpectedError);
}
