import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../animations/logo_animation.dart';

class HeaderSection extends StatelessWidget {
  final AnimationController logoAnimationController;
  final Animation<double> logoRotationAnimation;
  final Animation<double> logoScaleAnimation;
  final double screenWidth;

  const HeaderSection({
    super.key,
    required this.logoAnimationController,
    required this.logoRotationAnimation,
    required this.logoScaleAnimation,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SvgPicture.asset(
          "assets/curve_shape.svg",
          width: screenWidth,
          fit: BoxFit.fitWidth,
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              LogoAnimation(
                animationController: logoAnimationController,
                rotationAnimation: logoRotationAnimation,
                scaleAnimation: logoScaleAnimation,
                logoPath: "assets/logo.png",
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: logoAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: logoScaleAnimation.value,
                    child: const Text(
                      "Bizconnect",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A47D2),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }
}