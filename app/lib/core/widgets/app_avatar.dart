import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? fotoUrl;
  final double size;
  final int? hierarquiaNivel;
  final bool isGroup;
  final bool showOnline;
  final bool showEditBadge;
  final VoidCallback? onEditTap;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    required this.name,
    this.fotoUrl,
    this.size = 48,
    this.hierarquiaNivel,
    this.isGroup = false,
    this.showOnline = false,
    this.showEditBadge = false,
    this.onEditTap,
    this.onTap,
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

  Color get _hierarchyColor {
    if (isGroup) return AppColors.primary;
    if (hierarquiaNivel != null) {
      switch (hierarquiaNivel) {
        case 1:
          return const Color(0xFF7C3AED); // Roxo Direção
        case 2:
          return const Color(0xFF1565C0); // Azul Coordenação
        case 3:
          return const Color(0xFF0D9488); // Verde Supervisão
        default:
          return const Color(0xFF64748B); // Cinza Funcionário
      }
    }
    return AppColors.primary;
  }

  Widget _buildImage() {
    if (fotoUrl != null && fotoUrl!.trim().isNotEmpty) {
      final raw = fotoUrl!.trim();
      if (raw.startsWith('data:image')) {
        try {
          final base64String = raw.contains(',') ? raw.split(',')[1] : raw;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(),
          );
        } catch (_) {
          return _buildInitials();
        }
      } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return Image.network(
          raw,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(),
        );
      }
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      color: _hierarchyColor,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: _buildImage(),
    );

    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: avatar,
      );
    }

    if (!showOnline && !showEditBadge && hierarquiaNivel == null) {
      return SizedBox(width: size, height: size, child: avatar);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatar,
          if (showOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEditTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: EdgeInsets.all(size * 0.08),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: size * 0.24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
