import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

/// A consistent avatar widget that displays the user's profile photo
/// from the global [profilePhotoProvider] or Firebase Auth [photoURL],
/// falling back to a letter initial.
class UserAvatar extends ConsumerWidget {
  final double size;
  final double fontSize;

  const UserAvatar({
    super.key,
    this.size = 32,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoB64 = ref.watch(profilePhotoProvider);
    final authUser = ref.watch(authStateProvider).value;
    
    final photoUrl = authUser?.photoURL;
    final displayName = authUser?.displayName ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    Widget? avatarImage;

    if (photoB64 != null && photoB64.isNotEmpty) {
      try {
        final decoded = base64Decode(photoB64);
        avatarImage = Image.memory(
          decoded,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(initial),
        );
      } catch (_) {
        avatarImage = null;
      }
    }

    if (avatarImage == null && photoUrl != null && photoUrl.isNotEmpty) {
      avatarImage = Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(initial),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      child: avatarImage ?? _buildFallback(initial),
    );
  }

  Widget _buildFallback(String initial) {
    return Text(
      initial,
      style: GoogleFonts.fraunces(
        fontSize: fontSize,
        color: AppColors.background,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
