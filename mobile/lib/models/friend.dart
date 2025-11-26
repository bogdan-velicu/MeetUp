class Friend {
  final int userId;
  final String username;
  final String fullName;
  final double latitude;
  final double longitude;
  final String? accuracyM;
  final DateTime updatedAt;
  final String availabilityStatus;

  Friend({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.latitude,
    required this.longitude,
    this.accuracyM,
    required this.updatedAt,
    required this.availabilityStatus,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userId: json['user_id'],
      username: json['username'],
      fullName: json['full_name'],
      latitude: double.parse(json['latitude']),
      longitude: double.parse(json['longitude']),
      accuracyM: json['accuracy_m'],
      updatedAt: DateTime.parse(json['updated_at']),
      availabilityStatus: json['availability_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'full_name': fullName,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'accuracy_m': accuracyM,
      'updated_at': updatedAt.toIso8601String(),
      'availability_status': availabilityStatus,
    };
  }
}
