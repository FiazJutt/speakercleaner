import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LayeredContainer extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPowerPressed;

  const LayeredContainer({
    super.key,
    required this.isActive,
    required this.onPowerPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final layerColor = isDark
        ? AppColors.layerContainerDark
        : AppColors.layerContainer;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 260,
          child: Container(
            alignment: Alignment.center,
            child: _buildLayer(
              context: context,
              size: 260,
              color: layerColor.withOpacity(0.3),
              child: Container(
                alignment: Alignment.center,
                child: _buildLayer(
                  context: context,
                  size: 220,
                  color: layerColor.withOpacity(0.5),
                  child: Container(
                    alignment: Alignment.center,
                    child: _buildLayer(
                      context: context,
                      size: 180,
                      color: layerColor.withOpacity(0.7),
                      child: _buildLayer(
                        context: context,
                        size: 100,
                        color: layerColor.withOpacity(1),
                        child: _buildPowerButton(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayer({
    required BuildContext context,
    required double size,
    required Color color,
    Widget? child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPowerButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onPowerPressed,
      child: AvatarGlow(
        animate: isActive,
        glowColor: AppColors.powerButtonGreen,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        glowRadiusFactor: 0.48,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.powerButtonGreen
                : (isDark ? Colors.grey[800] : Colors.grey[400]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.powerButtonGreen.withOpacity(0.5)
                    : (isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3)),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.power_settings_new,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
