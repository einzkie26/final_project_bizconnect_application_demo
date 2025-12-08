import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileUtils {
  static Future<bool> isProfileComplete(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data() ?? {};
      return data['profileCompleted'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> markProfileComplete(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking profile complete: $e');
    }
  }

  static Future<void> resetProfileCompletion(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'profileCompleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error resetting profile completion: $e');
    }
  }
}