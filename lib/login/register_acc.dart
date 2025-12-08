import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../widgets/textfields/custom_text_field.dart';
import '../widgets/textfields/birthdate_field.dart';
import '../widgets/textfields/location_field.dart';
import '../widgets/common/toggle_button.dart';


class LoginRegisterPage extends ConsumerStatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  ConsumerState<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends ConsumerState<LoginRegisterPage>
    with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 80),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButton(text: "Login", isLogin: true),
                const SizedBox(width: 10),
                ToggleButton(text: "Register", isLogin: false),
              ],
            ),

            const SizedBox(height: 30),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Form(
                key: _formKey,
                child: Column(
                  children: authState.isLoginSelected
                      ? _loginFields()
                      : _registerFields(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (!authState.isLoginSelected &&
                      passwordController.text !=
                          confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Passwords do not match")),
                    );
                    return;
                  }
                  
                  if (authState.isLoginSelected) {
                    await _loginUser();
                  } else {
                    await _registerUser();
                  }
                }
              },
              child: Text(
                authState.isLoginSelected ? "Login" : "Register",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final authState = ref.read(authControllerProvider);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
        'email': emailController.text.trim(),
        'location': addressController.text.trim(),
        'birthdate': authState.selectedBirthdate,
        'isActive': true,
        'profileCompleted': false,
        'useCompanyName': false,
        'isWorkingAtCompany': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  Future<void> _loginUser() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  List<Widget> _loginFields() {
    return [
      CustomTextField(
        hint: "Email",
        controller: emailController,
        icon: Icons.email,
        validator: (v) => !v!.contains("@") ? "Enter a valid email" : null,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        hint: "Password",
        controller: passwordController,
        isPassword: true,
        icon: Icons.lock,
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    ];
  }

  List<Widget> _registerFields() {
    return [
      CustomTextField(
        hint: "First Name",
        controller: firstNameController,
        icon: Icons.person,
        validator: (v) => v!.isEmpty ? "First name is required" : null,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        hint: "Last Name",
        controller: lastNameController,
        icon: Icons.person_outline,
        validator: (v) => v!.isEmpty ? "Last name is required" : null,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        hint: "Email",
        controller: emailController,
        icon: Icons.email,
        validator: (v) => !v!.contains("@") ? "Enter a valid email" : null,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        hint: "Password",
        controller: passwordController,
        isPassword: true,
        icon: Icons.lock,
        validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        hint: "Confirm Password",
        controller: confirmPasswordController,
        isPassword: true,
        icon: Icons.lock_outline,
      ),
      const SizedBox(height: 20),
      LocationField(
        hint: "Address",
        controller: addressController,
        icon: Icons.home,
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
      const SizedBox(height: 20),
      const BirthdateField(),
    ];
  }
}
