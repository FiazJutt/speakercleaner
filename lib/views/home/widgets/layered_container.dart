import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 3 - Largest (bottom)
              Positioned(
                bottom: 0,
                child: _buildLayer(
                  size: 260,
                  color: AppColors.layerContainer.withOpacity(0.5),
                ),
              ),
              // Layer 2 - Medium
              Positioned(
                bottom: 20,
                child: _buildLayer(
                  size: 220,
                  color: AppColors.layerContainer.withOpacity(0.7),
                ),
              ),
              // Layer 1 - Smallest (top)
              Positioned(
                bottom: 40,
                child: _buildLayer(
                  size: 180,
                  color: AppColors.layerContainer.withOpacity(0.9),
                ),
              ),
              // Layer 1 - Smallest (top)
              Positioned(
                bottom: 60,
                child: _buildLayer(size: 140, color: AppColors.layerContainer),
              ),
              // // Layer 1 - Smallest (top)
              // Positioned(
              //   bottom: 80,
              //   child: _buildLayer(size: 100, color: AppColors.layerContainer),
              // ),
              // Power button - centered
              Center(child: _buildPowerButton()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLayer({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.containerShadow.withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerButton() {
    return GestureDetector(
      onTap: onPowerPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? AppColors.powerButtonGreen : Colors.grey,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppColors.powerButtonGreen.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.power_settings_new,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
