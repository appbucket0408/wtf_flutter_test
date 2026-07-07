/// Typed exception thrown by services; blocs catch it and surface
/// [userMessage] via toast/error states. [raw] keeps the original
/// error for logs and the DevPanel — never shown to users.
class AppException implements Exception {
  final String userMessage;
  final Object? raw;

  const AppException(this.userMessage, [this.raw]);

  @override
  String toString() => 'AppException($userMessage, raw: $raw)';
}
