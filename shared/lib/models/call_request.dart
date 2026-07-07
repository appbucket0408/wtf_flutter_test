enum CallStatus { pending, approved, declined, cancelled }

class CallRequest {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final String note;
  final CallStatus status;
  final String? declineReason;

  const CallRequest({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.requestedAt,
    required this.scheduledFor,
    required this.note,
    required this.status,
    this.declineReason,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'memberId': memberId,
        'trainerId': trainerId,
        'requestedAt': requestedAt.toIso8601String(),
        'scheduledFor': scheduledFor.toIso8601String(),
        'note': note,
        'status': status.name,
        'declineReason': declineReason,
      };

  factory CallRequest.fromMap(Map<String, dynamic> map) => CallRequest(
        id: map['id'] as String,
        memberId: map['memberId'] as String,
        trainerId: map['trainerId'] as String,
        requestedAt: DateTime.parse(map['requestedAt'] as String),
        scheduledFor: DateTime.parse(map['scheduledFor'] as String),
        note: map['note'] as String,
        status: CallStatus.values.byName(map['status'] as String),
        declineReason: map['declineReason'] as String?,
      );

  CallRequest copyWith({CallStatus? status, String? declineReason}) =>
      CallRequest(
        id: id,
        memberId: memberId,
        trainerId: trainerId,
        requestedAt: requestedAt,
        scheduledFor: scheduledFor,
        note: note,
        status: status ?? this.status,
        declineReason: declineReason ?? this.declineReason,
      );
}
