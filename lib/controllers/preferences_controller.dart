import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreferencesState {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool messageAlerts;
  final bool profileVisibility;
  final bool dataSharing;
  final bool darkMode;
  final bool isLoading;

  PreferencesState({
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.messageAlerts = true,
    this.profileVisibility = true,
    this.dataSharing = false,
    this.darkMode = false,
    this.isLoading = false,
  });

  PreferencesState copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? messageAlerts,
    bool? profileVisibility,
    bool? dataSharing,
    bool? darkMode,
    bool? isLoading,
  }) {
    return PreferencesState(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      messageAlerts: messageAlerts ?? this.messageAlerts,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      dataSharing: dataSharing ?? this.dataSharing,
      darkMode: darkMode ?? this.darkMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'messageAlerts': messageAlerts,
      'profileVisibility': profileVisibility,
      'dataSharing': dataSharing,
      'darkMode': darkMode,
    };
  }
}

class PreferencesController extends StateNotifier<PreferencesState> {
  PreferencesController() : super(PreferencesState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSigningOut = false;

  Future<void> loadPreferences() async {
    final user = _auth.currentUser;
    if (user == null || _isSigningOut) return;

    // indicate loading so UI can show progress if needed
    if (mounted) state = state.copyWith(isLoading: true);

    try {
      // add a timeout so a stalled network doesn't hang the app
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        state = state.copyWith(
          pushNotifications: data['pushNotifications'] ?? true,
          emailNotifications: data['emailNotifications'] ?? false,
          messageAlerts: data['messageAlerts'] ?? true,
          profileVisibility: data['profileVisibility'] ?? true,
          dataSharing: data['dataSharing'] ?? false,
          darkMode: data['darkMode'] ?? false,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on TimeoutException {
      // timeout - stop loading and keep current (or default) state
      if (mounted) state = state.copyWith(isLoading: false);
      print('Preferences load timed out');
    } catch (e) {
      // handle other errors gracefully (including permission-denied)
      if (mounted) state = state.copyWith(isLoading: false);
      print('Preferences load error: $e');
      // Use default preferences if there's a permission or network error
    }
  }

  Future<void> updatePreference(String key, bool value) async {
    final user = _auth.currentUser;
    if (user == null || _isSigningOut) return;

    // capture previous for potential revert
    final prevState = state;

    // Optimistically update local state so UI remains responsive,
    // and mark loading while attempting to persist the change.
    switch (key) {
      case 'pushNotifications':
        state = state.copyWith(pushNotifications: value, isLoading: true);
        break;
      case 'emailNotifications':
        state = state.copyWith(emailNotifications: value, isLoading: true);
        break;
      case 'messageAlerts':
        state = state.copyWith(messageAlerts: value, isLoading: true);
        break;
      case 'profileVisibility':
        state = state.copyWith(profileVisibility: value, isLoading: true);
        break;
      case 'dataSharing':
        state = state.copyWith(dataSharing: value, isLoading: true);
        break;
      case 'darkMode':
        state = state.copyWith(darkMode: value, isLoading: true);
        break;
      default:
        state = state.copyWith(isLoading: true);
    }

    try {
      // write with timeout to avoid indefinite hangs
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({key: value}).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Timeout: revert optimistic change and stop loading.
      if (mounted) state = prevState.copyWith(isLoading: false);
      print('Preferences update timed out for $key');
    } catch (e) {
      // On other errors revert optimistic state to keep UI consistent.
      if (mounted) state = prevState.copyWith(isLoading: false);
      print('Preferences update error for $key: $e');
    } finally {
      // ensure loading flag cleared if still mounted (in case write succeeded above)
      if (mounted && state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> signOut() async {
    _isSigningOut = true;
    try {
      // Clear all local state first
      state = PreferencesState();
      
      // Complete Firebase sign out
      await FirebaseAuth.instance.signOut();
      
      // Force clear auth persistence
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Verify sign out completed
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('Warning: User still authenticated after signOut');
        await FirebaseAuth.instance.signOut();
      }
      
    } catch (e) {
      print('Sign out error: $e');
      _isSigningOut = false;
    }
  }
}

final preferencesControllerProvider = StateNotifierProvider<PreferencesController, PreferencesState>((ref) {
  return PreferencesController();
});