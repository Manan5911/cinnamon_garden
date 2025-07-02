import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final _userCollection = FirebaseFirestore.instance.collection('users');
  final _auth = FirebaseAuth.instance;

  /// 🔹 Create user in Firebase Auth + Firestore (Admin action)
  Future<void> createUserWithCredentials({
    required String email,
    required String password,
    required String role, // 'manager' or 'kitchen'
    required String restaurantId, // ✅ Now required
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user!.uid;

    final user = UserModel(
      uid: uid,
      email: email,
      role: role,
      restaurantId: restaurantId, // ✅ Required field
      isActive: true,
    );

    await _userCollection.doc(uid).set(user.toMap());
  }

  /// 🔹 Create Firestore-only user
  Future<void> createUser(UserModel user) async {
    await _userCollection.doc(user.uid).set(user.toMap());
  }

  /// 🔹 Update existing user
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

  /// 🔹 Get users by role (manager / kitchen)
  Future<List<UserModel>> getUsersByRole(String role) async {
    final query = await _userCollection.where('role', isEqualTo: role).get();
    return query.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// 🔹 Revoke access (soft disable)
  Future<void> revokeUserAccess(String uid) async {
    await _userCollection.doc(uid).update({'isActive': false});
  }

  /// 🔹 Grant access (reactivate)
  Future<void> grantUserAccess(String uid) async {
    await _userCollection.doc(uid).update({'isActive': true});
  }
}
