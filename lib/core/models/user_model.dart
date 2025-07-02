class UserModel {
  final String uid;
  final String email;
  final String role; // admin, manager, kitchen
  final String restaurantId; // ✅ Now required
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.restaurantId, // ✅ Now required
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'],
      role: data['role'],
      restaurantId: data['restaurantId'], // ✅ Not nullable anymore
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'restaurantId': restaurantId,
      'isActive': isActive,
    };
  }
}
