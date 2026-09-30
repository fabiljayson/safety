class MissingChild {
  final int? id;
  final int userId;
  final String name;
  final int age;
  final String? photoUrl;
  final String? description;
  final String? lastClothes;
  final String status;
  final double disappearanceLat;
  final double disappearanceLng;
  final DateTime disappearedAt;
  final bool isVerified;
  final String alertType;

  const MissingChild({
    this.id,
    required this.userId,
    required this.name,
    required this.age,
    this.photoUrl,
    this.description,
    this.lastClothes,
    required this.status,
    required this.disappearanceLat,
    required this.disappearanceLng,
    required this.disappearedAt,
    this.isVerified = false,
    this.alertType = 'child_missing',
  });

  bool get isWantedPerson => alertType == 'wanted_person';
  bool get isAdultMissing => alertType == 'adult_missing';
  bool get isChildMissing => alertType == 'child_missing' || alertType.isEmpty;

  factory MissingChild.fromJson(Map<String, dynamic> json) {
    return MissingChild(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      age: json['age'] as int,
      photoUrl: json['photo_url'] as String?,
      description: json['description'] as String?,
      lastClothes: json['last_clothes'] as String?,
      status: json['status'] as String? ?? 'missing',
      disappearanceLat: (json['disappearance_lat'] as num).toDouble(),
      disappearanceLng: (json['disappearance_lng'] as num).toDouble(),
      disappearedAt: DateTime.parse(json['disappeared_at'] as String),
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      alertType: json['alert_type'] as String? ?? 'child_missing',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'age': age,
      'photo_url': photoUrl,
      'description': description,
      'last_clothes': lastClothes,
      'status': status,
      'disappearance_lat': disappearanceLat,
      'disappearance_lng': disappearanceLng,
      'disappeared_at': disappearedAt.toIso8601String(),
      'is_verified': isVerified,
      'alert_type': alertType,
    };
  }
}
