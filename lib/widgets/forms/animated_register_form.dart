import 'package:flutter/material.dart';

class AnimatedRegisterForm extends StatelessWidget {
  final AnimationController animationController;
  final String? selectedBirthdate;
  final Function(String) onBirthdateSelected;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const AnimatedRegisterForm({
    super.key,
    required this.animationController,
    this.selectedBirthdate,
    required this.onBirthdateSelected,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    final fields = [
      _inputFieldWithIcon("Username", Icons.person),
      _inputFieldWithIcon("Email", Icons.email),
      _inputFieldWithIcon("Password", Icons.lock, isPassword: true),
      _inputFieldWithIcon("Confirm Password", Icons.lock_outline, isPassword: true),
      _inputFieldWithIcon("Address", Icons.location_on),
      _birthdateFieldWithIcon(context),
    ];

    return Column(
      children: List.generate(fields.length, (index) {
        return Column(
          children: [
            AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animationController,
                    curve: Interval(
                      index * 0.1,
                      (index * 0.1) + 0.5,
                      curve: Curves.easeOutBack,
                    ),
                  )),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animationController,
                        curve: Interval(
                          index * 0.1,
                          (index * 0.1) + 0.5,
                        ),
                      ),
                    ),
                    child: fields[index],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      }),
    );
  }

  Widget _inputFieldWithIcon(String hint, IconData icon, {bool isPassword = false, TextEditingController? controller}) {
    return Container(
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
              controller: controller,
              obscureText: isPassword,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _birthdateFieldWithIcon(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          onBirthdateSelected("${picked.year}-${picked.month}-${picked.day}");
        }
      },
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8EAEF),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF6A5AE0),
              size: 20,
            ),
            const SizedBox(width: 15),
            Text(
              selectedBirthdate ?? "Birthdate",
              style: TextStyle(
                color: selectedBirthdate == null ? Colors.black54 : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}