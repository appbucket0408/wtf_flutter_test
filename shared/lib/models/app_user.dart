enum UserRole { trainer, member }

class AppUser {
  final String id;
  final UserRole role;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? assignedTrainerId;

  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.assignedTrainerId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.name,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'assignedTrainerId': assignedTrainerId,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String,
        role: UserRole.values.byName(map['role'] as String),
        name: map['name'] as String,
        email: map['email'] as String,
        avatarUrl: map['avatarUrl'] as String?,
        assignedTrainerId: map['assignedTrainerId'] as String?,
      );

  AppUser copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? assignedTrainerId,
  }) =>
      AppUser(
        id: id,
        role: role,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        assignedTrainerId: assignedTrainerId ?? this.assignedTrainerId,
      );
}
