import 'package:flutter/material.dart';

class CustomLoadingAnimation extends StatefulWidget {
  const CustomLoadingAnimation({super.key});

  @override
  _CustomLoadingAnimationState createState() => _CustomLoadingAnimationState();
}

class _CustomLoadingAnimationState extends State<CustomLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: RotationTransition(
            turns: _controller,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red,
                  width: 8,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
