class RoomMeta {
  final String id;
  final String callRequestId;

  /// Agora channel name (channels are created implicitly on join).
  final String channelId;
  final String roleMember;
  final String roleTrainer;

  const RoomMeta({
    required this.id,
    required this.callRequestId,
    required this.channelId,
    required this.roleMember,
    required this.roleTrainer,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'callRequestId': callRequestId,
        'channelId': channelId,
        'roleMember': roleMember,
        'roleTrainer': roleTrainer,
      };

  factory RoomMeta.fromMap(Map<String, dynamic> map) => RoomMeta(
        id: map['id'] as String,
        callRequestId: map['callRequestId'] as String,
        channelId: map['channelId'] as String,
        roleMember: map['roleMember'] as String,
        roleTrainer: map['roleTrainer'] as String,
      );
}
