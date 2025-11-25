import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final int currentPage;
  final bool isLastPage;

  OnboardingState({this.currentPage = 0, this.isLastPage = false});

  OnboardingState copyWith({int? currentPage, bool? isLastPage}) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isLastPage: isLastPage ?? this.isLastPage,
    );
  }
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return OnboardingState();
  }

  void setPage(int page, int totalPages) {
    state = state.copyWith(
      currentPage: page,
      isLastPage: page == totalPages - 1,
    );
  }

  void completeOnboarding() {
    // Logic to save onboarding completion state
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );
