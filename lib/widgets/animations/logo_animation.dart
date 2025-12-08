import 'package:flutter/material.dart';

class LogoAnimation extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> rotationAnimation;
  final Animation<double> scaleAnimation;
  final String logoPath;

  const LogoAnimation({
    super.key,
    required this.animationController,
    required this.rotationAnimation,
    required this.scaleAnimation,
    required this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Transform.rotate(
            angle: rotationAnimation.value * 0.5,
            child: SizedBox(
              height: 80,
              child: Image.asset(logoPath),
            ),
          ),
        );
      },
    );
  }
}