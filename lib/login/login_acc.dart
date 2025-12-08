import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../navigate/main_navigation.dart';
import '../widgets/animations/logo_animation.dart';
import '../admin/admin_dashboard.dart';
import '../widgets/textfields/location_field.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime? _selectedBirthdate;
  bool _isLoginSelected = true;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_animationController);
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6A5AE0), Color(0xFFE91E63)],
            ),
          ),
          child: Stack(
            children: [
              SvgPicture.asset(
                "assets/curve_shape.svg",
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fitWidth,
              ),
              
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                  
                      LogoAnimation(
                        animationController: _animationController,
                        rotationAnimation: _rotationAnimation,
                        scaleAnimation: _scaleAnimation,
                        logoPath: "assets/logo.png",
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Bizconnect',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A5AE0),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 80),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isLoginSelected = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isLoginSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: _isLoginSelected ? Color(0xFF6A5AE0) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isLoginSelected = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isLoginSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    color: !_isLoginSelected ? Color(0xFF6A5AE0) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoginSelected ? _buildLoginFields() : _buildRegisterFields(),
                    ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A90E2), Color(0xFF6A5AE0)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_isLoginSelected ? _login : _register),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isLoginSelected ? 'Login' : 'Register',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      Text(
                        _isLoginSelected ? "Didn't have an account?" : "Already have an account?",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isLoginSelected = !_isLoginSelected),
                        child: Text(
                          _isLoginSelected ? 'Register' : 'Login',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFields() {
    return Column(
      key: const ValueKey('login'),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Email',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterFields() {
    return Column(
      key: const ValueKey('register'),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              hintText: 'First Name',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              hintText: 'Last Name',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Email',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Confirm Password',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        LocationField(
          controller: _addressController,
          hint: 'Address',
          icon: Icons.home,
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: InkWell(
            onTap: () => _selectBirthdate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    _selectedBirthdate != null
                        ? '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}'
                        : 'Select Birthdate',
                    style: TextStyle(
                      color: _selectedBirthdate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resetAuthState() async {
    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(milliseconds: 100));
    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(milliseconds: 200));
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Warning: User still cached after reset: ${user.email}');
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _resetAuthState();
      
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user?.email != _emailController.text.trim()) {
        throw Exception('Authentication mismatch');
      }
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed: no user returned')),
        );
        return;
      }

      bool isAdmin = false;
      try {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 3));
        isAdmin = adminDoc.exists && (adminDoc.data()?['isActive'] == true);
      } catch (e) {
        isAdmin = false;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (!mounted) return;

      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  Future<void> _register() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required')),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      await _resetAuthState();
      
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user?.email != _emailController.text.trim()) {
        throw Exception('Registration authentication mismatch');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'email': _emailController.text.trim(),
        'location': _addressController.text.trim(),
        'birthdate': _selectedBirthdate?.toIso8601String(),
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

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
