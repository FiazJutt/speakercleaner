import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class PremiumOfferContent extends StatelessWidget {
  final String imagePath;

  const PremiumOfferContent({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we're using dark theme or light theme
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final Color textColor = isDarkMode 
        ? AppColors.textPrimary 
        : AppColors.textPrimaryLight;
        
    final Color secondaryTextColor = isDarkMode 
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

        // Text area with premium offer content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Small text at top
              Text(
                'Get ultimate access to all premium features',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 16),
              
              // Big and bold features
              Text(
                'Ultimate Use, Turbo Mode & Different Sound Waves',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Try for free text
              Text(
                'Try 3 days for free',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              
              // Price text
              Text(
                'Rs 900 per week',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
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