import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _inputField("Username or Email"),
        const SizedBox(height: 20),
        _inputField("Password", isPassword: true),
      ],
    );
  }

  Widget _inputField(String hint, {bool isPassword = false}) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EAEF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }
}