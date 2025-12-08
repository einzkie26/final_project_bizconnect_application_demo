import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_model.dart';

class AdminController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> signInAdmin(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final adminDoc = await _firestore
          .collection('admins')
          .doc(credential.user!.uid)
          .get();
      
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<AdminModel?> getCurrentAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (doc.exists) {
        return AdminModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createAdminIfNotExists() async {
    try {
      final adminCheck = await _firestore
          .collection('admins')
          .where('email', isEqualTo: 'connectadmin@gmail.com')
          .get();
      
      if (adminCheck.docs.isEmpty) {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: 'connectadmin@gmail.com',
          password: 'admin123',
        );
        
        final admin = AdminModel(
          id: credential.user!.uid,
          name: 'Admin',
          email: 'connectadmin@gmail.com',
          role: 'admin',
          createdAt: DateTime.now(),
        );
        
        await _firestore
            .collection('admins')
            .doc(admin.id)
            .set(admin.toMap());
        
        await _auth.signOut();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final adminControllerProvider = Provider<AdminController>((ref) {
  return AdminController();
});