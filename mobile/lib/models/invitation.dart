class OrganizerInfo {
  final int id;
  final String username;
  final String? fullName;
  final String? profilePhotoUrl;

  OrganizerInfo({
    required this.id,
    required this.username,
    this.fullName,
    this.profilePhotoUrl,
  });

  factory OrganizerInfo.fromJson(Map<String, dynamic> json) {
    return OrganizerInfo(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }
}

class MeetingInfo {
  final int id;
  final String? title;
  final String? description;
  final String? latitude;
  final String? longitude;
  final String? address;
  final DateTime scheduledAt;
  final String status;
  final DateTime createdAt;

  MeetingInfo({
    required this.id,
    this.title,
    this.description,
    this.latitude,
    this.longitude,
    this.address,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
  });

  factory MeetingInfo.fromJson(Map<String, dynamic> json) {
    return MeetingInfo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Invitation {
  final int id; // This is the meeting_id
  final MeetingInfo meeting;
  final OrganizerInfo organizer;
  final String participantStatus;
  final DateTime invitedAt;
  final DateTime? respondedAt;

  Invitation({
    required this.id,
    required this.meeting,
    required this.organizer,
    required this.participantStatus,
    required this.invitedAt,
    this.respondedAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      meeting: MeetingInfo.fromJson(json['meeting']),
      organizer: OrganizerInfo.fromJson(json['organizer']),
      participantStatus: json['participant_status'],
      invitedAt: DateTime.parse(json['invited_at']),
      respondedAt: json['responded_at'] != null 
          ? DateTime.parse(json['responded_at']) 
          : null,
    );
  }
}

