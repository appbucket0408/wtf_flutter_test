class SessionLog {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final int? rating;
  final String? trainerNotes;
  final String? memberNotes;

  const SessionLog({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.rating,
    this.trainerNotes,
    this.memberNotes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'memberId': memberId,
        'trainerId': trainerId,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationSec': durationSec,
        'rating': rating,
        'trainerNotes': trainerNotes,
        'memberNotes': memberNotes,
      };

  factory SessionLog.fromMap(Map<String, dynamic> map) => SessionLog(
        id: map['id'] as String,
        memberId: map['memberId'] as String,
        trainerId: map['trainerId'] as String,
        startedAt: DateTime.parse(map['startedAt'] as String),
        endedAt: DateTime.parse(map['endedAt'] as String),
        durationSec: map['durationSec'] as int,
        rating: map['rating'] as int?,
        trainerNotes: map['trainerNotes'] as String?,
        memberNotes: map['memberNotes'] as String?,
      );

  SessionLog copyWith({int? rating, String? trainerNotes, String? memberNotes}) =>
      SessionLog(
        id: id,
        memberId: memberId,
        trainerId: trainerId,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSec: durationSec,
        rating: rating ?? this.rating,
        trainerNotes: trainerNotes ?? this.trainerNotes,
        memberNotes: memberNotes ?? this.memberNotes,
      );
}
