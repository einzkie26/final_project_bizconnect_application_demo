import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugUserPage extends StatelessWidget {
  const DebugUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Debug User')),
      body: Column(
        children: [
          Text('User: ${user?.email ?? 'None'}'),
          Text('UID: ${user?.uid ?? 'None'}'),
          if (user != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    children: [
                      Text('Phone: ${data['phoneNumber'] ?? 'Missing'}'),
                      Text('Bio: ${data['bio'] ?? 'Missing'}'),
                      Text('Profile Complete: ${data['profileCompleted'] ?? false}'),
                    ],
                  );
                }
                return const Text('No user data');
              },
            ),
          ElevatedButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}