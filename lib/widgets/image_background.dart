import 'package:flutter/material.dart';

class ImageBackground extends StatelessWidget {
  final String assetPath;
  final double opacity;

  const ImageBackground({
    super.key,
    required this.assetPath,
    this.opacity = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
          ),
          // Overlay para bajar brillo
          Container(color: Colors.black.withOpacity(opacity)),
        ],
      ),
    );
  }
}
