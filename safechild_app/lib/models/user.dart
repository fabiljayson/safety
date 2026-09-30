class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final double? lastLat;
  final double? lastLng;
  final String? fcmToken;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.lastLat,
    this.lastLng,
    this.fcmToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      lastLat: json['last_lat'] != null
          ? double.parse(json['last_lat'].toString())
          : null,
      lastLng: json['last_lng'] != null
          ? double.parse(json['last_lng'].toString())
          : null,
      fcmToken: json['fcm_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'last_lat': lastLat,
      'last_lng': lastLng,
      'fcm_token': fcmToken,
    };
  }
}
