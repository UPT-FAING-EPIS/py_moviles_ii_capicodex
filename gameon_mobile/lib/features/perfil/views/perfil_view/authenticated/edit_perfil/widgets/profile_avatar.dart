import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String initial;
  final VoidCallback onTap;
  final String? imageUrl;
  final Uint8List? pendingImageBytes;

  const ProfileAvatar({
    super.key,
    required this.initial,
    required this.onTap,
    this.imageUrl,
    this.pendingImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary.withValues(alpha: .4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: pendingImageBytes != null
                  ? Image.memory(
                      pendingImageBytes!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : imageUrl != null &&
                        imageUrl!.isNotEmpty &&
                        imageUrl != 'pending'
                  ? Image.network(
                      imageUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Center(
                        child: Text(
                          initial.isNotEmpty ? initial[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial.isNotEmpty ? initial[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 3),
              ),
              child: Icon(Icons.camera_alt, color: colors.onPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
