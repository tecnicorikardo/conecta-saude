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
  final bool? isWorking;

  const ConversationAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.isGroup = false,
    this.size = 40,
    this.showOnline = false,
    this.hierarquiaNivel,
    this.isWorking,
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

    if (isGroup) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatarChild,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(Icons.groups, size: size * 0.28, color: Colors.white),
            ),
          ),
        ],
      );
    }

    final showStatus = !isGroup && (isWorking != null || showOnline);
    if (!showStatus) return avatarChild;

    final inService = isWorking ?? showOnline;
    final dotColor = inService ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarChild,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: size * 0.32,
            height: size * 0.32,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.35),
                  blurRadius: 3,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: !inService
                ? Icon(
                    Icons.nightlight_round,
                    size: size * 0.18,
                    color: Colors.white,
                  )
                : null,
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
