import 'package:hive/hive.dart';

part 'missing_child.g.dart';

@HiveType(typeId: 0)
class MissingChild extends HiveObject {
  @HiveField(0)
  final int? id;
  @HiveField(1)
  final int userId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final int age;
  @HiveField(4)
  final String? photoUrl;
  @HiveField(5)
  final String? description;
  @HiveField(6)
  final String? lastClothes;
  @HiveField(7)
  final String status;
  @HiveField(8)
  final double disappearanceLat;
  @HiveField(9)
  final double disappearanceLng;
  @HiveField(10)
  final DateTime disappearedAt;
  @HiveField(11)
  final bool isVerified;
  @HiveField(12)
  final String alertType;

  MissingChild({
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
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      age: json['age'],
      photoUrl: json['photo_url'],
      description: json['description'],
      lastClothes: json['last_clothes'],
      status: json['status'] ?? 'missing',
      disappearanceLat: double.parse(json['disappearance_lat'].toString()),
      disappearanceLng: double.parse(json['disappearance_lng'].toString()),
      disappearedAt: DateTime.parse(json['disappeared_at']),
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      alertType: json['alert_type'] ?? 'child_missing',
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
