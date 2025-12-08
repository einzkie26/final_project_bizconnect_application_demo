import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      return doc.exists && doc.data()?['isActive'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> loginAdmin(String email, String password) async {
    try {
      // Force complete sign out first
      await _auth.signOut();
      await Future.delayed(const Duration(milliseconds: 200));
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        await _auth.signOut();
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> createAdmin(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _firestore.collection('admins').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'admin',
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}