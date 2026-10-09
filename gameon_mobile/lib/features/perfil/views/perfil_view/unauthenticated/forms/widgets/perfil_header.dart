import 'package:flutter/material.dart';
import 'header_clipper.dart';

class PerfilHeader extends StatelessWidget {
  final Size size;
  final double extraTop;
  const PerfilHeader({super.key, required this.size, required this.extraTop});

  @override
  Widget build(BuildContext context) {
    final headerHeight = size.height * 0.28 + extraTop;
    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF388E3C),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 32 + extraTop, 24, 0),
            child: const Text(
              'Te damos la\n'
              'bienvenida',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
