class ParticipantUserInfo {
  final int id;
  final String username;
  final String? fullName;
  final String? profilePhotoUrl;

  ParticipantUserInfo({
    required this.id,
    required this.username,
    this.fullName,
    this.profilePhotoUrl,
  });

  factory ParticipantUserInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantUserInfo(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }
}

class MeetingParticipant {
  final int id;
  final int meetingId;
  final int userId;
  final String status; // pending, accepted, declined
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ParticipantUserInfo? user;

  MeetingParticipant({
    required this.id,
    required this.meetingId,
    required this.userId,
    required this.status,
    this.confirmedAt,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory MeetingParticipant.fromJson(Map<String, dynamic> json) {
    return MeetingParticipant(
      id: json['id'],
      meetingId: json['meeting_id'],
      userId: json['user_id'],
      status: json['status'],
      confirmedAt: json['confirmed_at'] != null 
          ? DateTime.parse(json['confirmed_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null 
          ? ParticipantUserInfo.fromJson(json['user'])
          : null,
    );
  }
}

class Meeting {
  final int id;
  final int organizerId;
  final String? title;
  final String? description;
  final int? locationId;
  final String? latitude;
  final String? longitude;
  final String? address;
  final DateTime scheduledAt;
  final String status; // pending, confirmed, cancelled, completed
  final DateTime createdAt;
  final DateTime updatedAt;
  final int participantCount; // Count from backend (always available)
  final List<MeetingParticipant> participants;

  Meeting({
    required this.id,
    required this.organizerId,
    this.title,
    this.description,
    this.locationId,
    this.latitude,
    this.longitude,
    this.address,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.participantCount = 0,
    required this.participants,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      organizerId: json['organizer_id'],
      title: json['title'],
      description: json['description'],
      locationId: json['location_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      participantCount: json['participant_count'] ?? (json['participants'] as List<dynamic>?)?.length ?? 0,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => MeetingParticipant.fromJson(p))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizer_id': organizerId,
      'title': title,
      'description': description,
      'location_id': locationId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }
}

extension MeetingParticipantExtension on MeetingParticipant {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meeting_id': meetingId,
      'user_id': userId,
      'status': status,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

