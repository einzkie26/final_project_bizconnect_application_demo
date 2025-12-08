import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'dart:async';

class ProfileController extends StateNotifier<UserModel?> {
  ProfileController(this._ref) : super(null) {
    _init();
  }

  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _userSubscription;
  StreamSubscription? _authSubscription;

  void _init() {
    // Listen to auth state changes
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _clearUserData();
      }
    });
  }

  void _loadUserData(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _firestore.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        state = UserModel.fromMap(doc.data()!, doc.id);
      }
    });
  }

  void _clearUserData() {
    _userSubscription?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> reloadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        state = UserModel.fromMap(doc.data()!, doc.id);
      }
    }
  }

  String getDisplayName() {
    if (state == null) return 'User';
    
    // Always show the user's actual name first
    if (state!.name.isNotEmpty) {
      return state!.name;
    }
    
    // Fallback to company name if name is empty
    if (state!.useCompanyName && state!.isWorkingAtCompany && state!.companyName != null) {
      return state!.companyName!;
    }
    
    return 'User';
  }

  String getDisplayDetails() {
    if (state == null) return '';
    
    // Show company name if using company name mode
    if (state!.useCompanyName && state!.isWorkingAtCompany && state!.companyName != null && state!.companyName!.isNotEmpty) {
      return state!.companyName!;
    }
    
    // Show position if working at company but in personal mode
    if (state!.isWorkingAtCompany && state!.position != null && state!.position!.isNotEmpty) {
      return state!.position!;
    }
    
    return state!.email;
  }

  String getDisplayInitial() {
    if (state == null) return 'U';
    
    if (state!.useCompanyName && state!.isWorkingAtCompany && state!.companyName != null) {
      return state!.companyName!.substring(0, 1).toUpperCase();
    }
    
    return state!.name.substring(0, 1).toUpperCase();
  }

  Future<void> toggleDisplayName() async {
    final user = _auth.currentUser;
    if (user == null || state == null) return;

    final newValue = !state!.useCompanyName;
    await _firestore.collection('users').doc(user.uid).update({
      'useCompanyName': newValue,
    });
  }

  void clearProfile() {
    _clearUserData();
  }

  void refreshProfile() {
    final user = _auth.currentUser;
    if (user != null) {
      _loadUserData(user.uid);
    }
  }
}

final profileControllerProvider = StateNotifierProvider<ProfileController, UserModel?>((ref) {
  return ProfileController(ref);
});