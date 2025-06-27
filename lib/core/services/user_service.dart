import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _userCollection = FirebaseFirestore.instance.collection('users');

  /// 🔹 Create a new user
  Future<void> createUser(UserModel user) async {
    await _userCollection.doc(user.uid).set(user.toMap());
  }

  /// 🔹 Update an existing user
  Future<void> updateUser(UserModel user) async {
    await _userCollection.doc(user.uid).update(user.toMap());
  }

  /// 🔹 Delete user permanently
  Future<void> deleteUser(String uid) async {
    await _userCollection.doc(uid).delete();
  }

  /// 🔹 Get user by UID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _userCollection.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// 🔹 Get all users
  Future<List<UserModel>> getAllUsers() async {
    final query = await _userCollection.get();
    return query.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// 🔹 Get users by role (admin, manager, kitchen)
  Future<List<UserModel>> getUsersByRole(String role) async {
    final query = await _userCollection.where('role', isEqualTo: role).get();
    return query.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// 🔹 Revoke access (soft delete)
  Future<void> revokeUserAccess(String uid) async {
    await _userCollection.doc(uid).update({'isActive': false});
  }

  /// 🔹 Grant/Re-activate access
  Future<void> grantUserAccess(String uid) async {
    await _userCollection.doc(uid).update({'isActive': true});
  }
}
