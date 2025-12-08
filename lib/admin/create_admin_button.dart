import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAdminButton extends StatelessWidget {
  const CreateAdminButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: 'connectadmin@gmail.com',
            password: 'admin',
          );
          
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(credential.user!.uid)
              .set({
            'name': 'Admin',
            'email': 'connectadmin@gmail.com',
            'isActive': true,
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin created successfully!')),
          );
          
          await FirebaseAuth.instance.signOut();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      },
      child: const Text('Create Admin'),
    );
  }
}