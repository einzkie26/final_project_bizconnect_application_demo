import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userDataStreamProvider = StreamProvider<DocumentSnapshot?>((ref) {
  final user = ref.watch(userStreamProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
});

final companiesStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance.collection('companies').snapshots();
});

final messagesStreamProvider = StreamProvider.family<QuerySnapshot, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .where('receiverId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots();
});
