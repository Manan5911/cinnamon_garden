class AppUser {
  final String uid;
  final String email;
  final String role; // 'admin', 'manager', 'kitchen'
  final String? restaurant; // null for admin

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.restaurant,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      restaurant: map['restaurant'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role, 'restaurant': restaurant};
  }
}
