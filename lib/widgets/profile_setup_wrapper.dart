import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile_setup/profile_details_page.dart';
import '../navigate/main_navigation.dart';

class ProfileSetupWrapper extends StatelessWidget {
  const ProfileSetupWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return ProfileDetailsPage(userId: user.uid);
        }

        // Temporarily bypass profile check for testing
        return const MainNavigation();
        
        // final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        // final hasPhone = userData['phoneNumber'] != null && userData['phoneNumber'].toString().isNotEmpty;
        // final hasBio = userData['bio'] != null && userData['bio'].toString().isNotEmpty;
        // 
        // if (hasPhone && hasBio) {
        //   return const MainNavigation();
        // } else {
        //   return ProfileDetailsPage(userId: user.uid);
        // }
      },
    );
  }
}