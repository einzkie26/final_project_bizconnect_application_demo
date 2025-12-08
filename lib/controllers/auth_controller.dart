import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_state_model.dart';
import '../models/user_model.dart';

class AuthController extends StateNotifier<AuthStateModel> {
  AuthController() : super(AuthStateModel());
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  void toggleLoginRegister(bool isLogin) {
    state = state.copyWith(isLoginSelected: isLogin);
  }
  
  void setBirthdate(String birthdate) {
    state = state.copyWith(selectedBirthdate: birthdate);
  }

  Future<bool> signIn(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Force complete sign out first
      await _auth.signOut();
      await Future.delayed(const Duration(milliseconds: 200));
      
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name, String? location) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        birthdate: state.selectedBirthdate,
        location: location,
        createdAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void signOut() {
    FirebaseAuth.instance.signOut();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthStateModel>((ref) {
  return AuthController();
});