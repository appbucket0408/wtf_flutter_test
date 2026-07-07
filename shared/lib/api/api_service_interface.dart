/// Credentials needed to join an RTC channel.
class RtcCredentials {
  final String token;
  final String appId;
  final int uid;

  const RtcCredentials({
    required this.token,
    required this.appId,
    required this.uid,
  });
}

/// Contract for the token-server API. Domain services depend on this
/// interface — never on Dio directly — keeping the API layer mockable.
abstract class ApiServiceInterface {
  /// Agora RTC credentials for joining channel [roomId] as [role].
  Future<RtcCredentials> getAuthToken({
    required String userId,
    required String role,
    required String roomId,
  });

  /// Register/echo an RTC channel; returns the channel id. Idempotent.
  Future<String> createRoom(String name);
}
