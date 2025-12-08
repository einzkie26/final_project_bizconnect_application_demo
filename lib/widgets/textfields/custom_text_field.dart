import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final IconData icon;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.validator,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFF8EAEF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: InputBorder.none,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}