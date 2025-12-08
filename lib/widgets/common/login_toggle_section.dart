import 'package:flutter/material.dart';

class LoginToggleSection extends StatefulWidget {
  final bool isLoginSelected;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const LoginToggleSection({
    super.key,
    required this.isLoginSelected,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  State<LoginToggleSection> createState() => _LoginToggleSectionState();
}

class _LoginToggleSectionState extends State<LoginToggleSection>
    with TickerProviderStateMixin {
  late AnimationController _loginAnimationController;
  late AnimationController _registerAnimationController;
  late Animation<double> _loginScaleAnimation;
  late Animation<double> _registerScaleAnimation;

  @override
  void initState() {
    super.initState();
    _loginAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _registerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _loginScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _loginAnimationController, curve: Curves.easeInOut),
    );
    _registerScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _registerAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _loginAnimationController.dispose();
    _registerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _loginScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _loginScaleAnimation.value,
                  child: GestureDetector(
                    onTapDown: (_) => _loginAnimationController.forward(),
                    onTapUp: (_) => _loginAnimationController.reverse(),
                    onTapCancel: () => _loginAnimationController.reverse(),
                    onTap: widget.onLoginTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: widget.isLoginSelected
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF5B5FE9),
                                  Color(0xFFA79CFF)
                                ],
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: widget.isLoginSelected
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _registerScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _registerScaleAnimation.value,
                  child: GestureDetector(
                    onTapDown: (_) => _registerAnimationController.forward(),
                    onTapUp: (_) => _registerAnimationController.reverse(),
                    onTapCancel: () => _registerAnimationController.reverse(),
                    onTap: widget.onRegisterTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: !widget.isLoginSelected
                            ? Colors.white
                            : Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Register",
                        style: TextStyle(
                          color: !widget.isLoginSelected
                              ? Color(0xFF6A5AE0)
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}