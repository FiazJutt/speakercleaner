import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../viewmodels/onboarding_viewmodel.dart';
import '../home/home_screen.dart';
import 'widgets/onboarding_content.dart';
import 'widgets/premium_offer_content.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const OnboardingContent(
      imagePath: AppConstants.onboarding1,
      title: 'Best Way to Clean the Speaker',
      description:
          'Eject water from your speakers with our advanced sound wave technology.',
    ),
    const OnboardingContent(
      imagePath: AppConstants.onboarding2,
      title: 'Different Sound Waves',
      description: 'Remove dust particles and improve sound clarity instantly.',
    ),
    const OnboardingContent(
      imagePath: AppConstants.onboarding3,
      title: 'Switch Speakers',
      description:
          'Test left and right channels to ensure your speakers are working perfectly.',
    ),
    const OnboardingContent(
      imagePath: AppConstants.onboarding4,
      title: 'Thats Super easy',
      description: 'Generate custom frequencies to test your audio equipment.',
    ),
    // Last screen with premium offer
    const PremiumOfferContent(
      imagePath: AppConstants.onboarding5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final viewModel = ref.read(onboardingProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              viewModel.setPage(index, _pages.length);
            },
            children: _pages.map((page) {
              return Container(
                padding: const EdgeInsets.only(bottom: 100), // Make room for navigation
                child: page,
              );
            }).toList(),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Center(
              child: SizedBox(
                width: 200, // Fixed width for the button
                child: ElevatedButton(
                  onPressed: () {
                    if (onboardingState.isLastPage) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    onboardingState.isLastPage ? 'Get Started' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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