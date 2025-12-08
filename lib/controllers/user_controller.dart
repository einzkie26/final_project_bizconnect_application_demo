import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList(),
    ).handleError((error) {
      // Return empty list on any error (including permission-denied)
      return <UserModel>[];
    });
  }

  Future<void> toggleCompanyMode(String userId, bool isCompanyMode, String? companyId) async {
    await _firestore.collection('users').doc(userId).update({
      'isCompanyMode': isCompanyMode,
      'activeCompanyId': companyId,
    });
  }
}

final userControllerProvider = Provider<UserController>((ref) {
  return UserController();
});