/// Token-server endpoint paths.
abstract final class ApiEndpoints {
  /// Base URL comes from --dart-define; 10.0.2.2 reaches the host Mac
  /// from an Android emulator. Use the Mac's LAN IP for real devices.
  static const baseUrl = String.fromEnvironment(
    'TOKEN_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const token = '/token';
  static const room = '/room';
  static const health = '/health';
}
