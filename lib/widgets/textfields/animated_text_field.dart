import 'package:flutter/material.dart';

class AnimatedTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const AnimatedTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8EAEF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF6A5AE0),
                size: 20,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  obscureText: isPassword,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}