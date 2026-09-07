import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ConversationAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool isGroup;
  final double size;
  final bool showOnline;
  final int? hierarquiaNivel;

  const ConversationAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.isGroup = false,
    this.size = 40,
    this.showOnline = false,
    this.hierarquiaNivel,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  Color get _backgroundColor {
    if (isGroup) return AppColors.primary;
    if (hierarquiaNivel != null) {
      switch (hierarquiaNivel) {
        case 1:
          return const Color(0xFF7C3AED);
        case 2:
          return AppColors.primary;
        case 3:
          return const Color(0xFF0D9488);
        default:
          return const Color(0xFF64748B);
      }
    }
    const colors = [
      AppColors.primary,
      Color(0xFF7C3AED),
      Color(0xFF0D9488),
      Color(0xFFD97706),
      Color(0xFFE11D48),
      Color(0xFF2563EB),
    ];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      final raw = photoUrl!.trim();
      if (raw.startsWith('data:image')) {
        try {
          final b64 = raw.contains(',') ? raw.split(',')[1] : raw;
          avatarChild = ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.memory(
              base64Decode(b64),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(),
            ),
          );
        } catch (_) {
          avatarChild = _buildFallback();
        }
      } else {
        avatarChild = ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.network(
            raw,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(),
          ),
        );
      }
    } else {
      avatarChild = _buildFallback();
    }

    if (!showOnline) return avatarChild;

    return Stack(
      children: [
        avatarChild,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isGroup
          ? Icon(Icons.group, size: size * 0.55, color: Colors.white)
          : Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
    );
  }
}
