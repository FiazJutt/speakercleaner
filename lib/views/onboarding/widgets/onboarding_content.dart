import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class OnboardingContent extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingContent({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we're using dark theme or light theme
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final Color titleColor = isDarkMode 
        ? AppColors.textPrimary 
        : AppColors.textPrimaryLight;
        
    final Color descriptionColor = isDarkMode 
        ? AppColors.textSecondary 
        : AppColors.textSecondaryLight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Image container with fixed size
        Container(
          height: 300, // Adjust this value as needed
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Text area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: descriptionColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 50), // Add some spacing at the bottom
      ],
    );
  }
}