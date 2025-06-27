class UserModel {
  final String uid;
  final String email;
  final String role; // admin, manager, kitchen
  final String? restaurantId;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.restaurantId,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'],
      role: data['role'],
      restaurantId: data['restaurantId'],
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
