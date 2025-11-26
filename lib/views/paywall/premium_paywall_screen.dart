import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../viewmodels/subscription_provider.dart';
// import '../config/app_config.dart'; // Remove or replace if not used

class PremiumPaywallScreen extends ConsumerStatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  ConsumerState<PremiumPaywallScreen> createState() =>
      _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends ConsumerState<PremiumPaywallScreen>
    with TickerProviderStateMixin {
  int selectedIndex = 1;
  bool isLoading = false;
  bool freeTrialEnabled =
      true; // Default to false since yearly is selected first

  List<Package> packages = [];
  StoreProduct skuFirst = const StoreProduct("", "", "", 0.0, "0.0", "USD");
  StoreProduct skuSecond = const StoreProduct("", "", "", 0.0, "0.0", "USD");

  List<StoreProduct> products = [];

  // Animation variables
  late AnimationController _animationController;
  late Animation<double> _bellAnimation;
  late Animation<double> _scaleAnimation;

  Future fetchOffers() async {
    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current != null) {
        final availablePackages = offerings.current!.availablePackages;

        if (availablePackages.isNotEmpty) {
          // Sort packages to put yearly first, then monthly, then weekly
          final sortedPackages = List.from(availablePackages);
          sortedPackages.sort((a, b) {
            // Yearly packages first
            if (a.packageType == PackageType.annual &&
                b.packageType != PackageType.annual) {
              return -1;
            }
            if (b.packageType == PackageType.annual &&
                a.packageType != PackageType.annual) {
              return 1;
            }
            // Monthly packages second
            if (a.packageType == PackageType.monthly &&
                b.packageType == PackageType.weekly) {
              return -1;
            }
            if (b.packageType == PackageType.monthly &&
                a.packageType == PackageType.weekly) {
              return 1;
            }
            return 0;
          });

          setState(() {
            packages = sortedPackages.cast<Package>();

            // Get first two packages (yearly first, then monthly/weekly)
            if (sortedPackages.length >= 2) {
              skuFirst = sortedPackages[0].storeProduct; // Yearly
              skuSecond = sortedPackages[1].storeProduct; // Monthly/Weekly
              products = [skuFirst, skuSecond];
            } else if (sortedPackages.length == 1) {
              skuFirst = sortedPackages[0].storeProduct;
              skuSecond = sortedPackages[0].storeProduct;
              products = [skuFirst];
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching offers: $e');
    }
  }

  void buySubscription() async {
    debugPrint(
      "Buying Package at index: $selectedIndex for ${packages[selectedIndex].storeProduct.title}",
    );
    setState(() {
      isLoading = true;
    });

    if (packages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please check your internet connection or your device does not support in-app purchases',
          ),
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Get the selected package based on selectedIndex
      final selectedPackage = packages[selectedIndex];
      // final subscriptionService = context.read<SubscriptionService>();
      final subscriptionServiceProvider = ref.read(subscriptionProvider);
      final success = await subscriptionServiceProvider.purchasePremium(
        selectedPackage,
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase Successful'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize bell animation - faster ringing with pauses
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Total cycle: 2 seconds
      vsync: this,
    );

    // Bell ringing animation (fast left-right movement for first 800ms, then pause)
    _bellAnimation = TweenSequence<double>([
      // Rapid ringing for 800ms
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.2,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.2,
          end: -0.2,
        ).chain(CurveTween(curve: Curves.elasticInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.2,
          end: 0.2,
        ).chain(CurveTween(curve: Curves.elasticInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.2,
          end: -0.2,
        ).chain(CurveTween(curve: Curves.elasticInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.2,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 10,
      ),
      // Pause for 1 second (remaining 1200ms)
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 50),
    ]).animate(_animationController);

    // Subtle scale animation that matches the bell ringing
    _scaleAnimation = TweenSequence<double>([
      // Scale up slightly during ringing
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      // Scale back to normal
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      // Stay at normal scale during pause
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
    ]).animate(_animationController);

    // Start the animation and repeat
    _animationController.repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchOffers();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // App Logo and Name
                  _buildHeader(),
                  const SizedBox(height: 20),
                  // Features List
                  _buildFeaturesList(),
                  const SizedBox(height: 20),
                  // Pricing Plans
                  _buildPricingPlans(),
                  const SizedBox(height: 16),
                  // Free Trial Toggle
                  _buildFreeTrialToggle(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          // Bottom Purchase Section
          _buildBottomPurchaseSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // App icon/logo with animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _bellAnimation.value,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/icons/icon.png'),
                              fit: BoxFit.cover,
                            ),
                            // border: Border.all(
                            //   color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            //   width: 2,
                            // ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // App name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Speaker Cleaner',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    fontFamily: 'Arial',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pro',
                    style: TextStyle(
                      color: !isDark ? Colors.white : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final theme = Theme.of(context);

    final features = [
      {'icon': Icons.graphic_eq, 'text': 'Unlock all wave types'},
      {'icon': Icons.all_inclusive, 'text': 'Unlimited cleaning sessions'},
      {'icon': Icons.cleaning_services, 'text': 'Advanced cleaning modes'},
      {
        'icon': CupertinoIcons.hand_thumbsup_fill,
        'text': 'Support Development',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature['text'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  /// Calculates the discount percentage between two packages
  String? _calculateDiscountBadge(Package firstPackage, Package secondPackage) {
    try {
      final firstPrice = firstPackage.storeProduct.price;
      final secondPrice = secondPackage.storeProduct.price;

      if (firstPrice <= 0 || secondPrice <= 0) return null;

      double firstTotalCost;
      double secondTotalCost;

      // Calculate total cost for first package (yearly)
      if (firstPackage.packageType == PackageType.annual) {
        firstTotalCost = firstPrice; // One-time payment
      } else if (firstPackage.packageType == PackageType.monthly) {
        firstTotalCost = firstPrice * 12; // 12 months
      } else if (firstPackage.packageType == PackageType.weekly) {
        firstTotalCost = firstPrice * 52; // 52 weeks
      } else {
        firstTotalCost = firstPrice;
      }

      // Calculate total cost for second package
      if (secondPackage.packageType == PackageType.annual) {
        secondTotalCost = secondPrice; // One-time payment
      } else if (secondPackage.packageType == PackageType.monthly) {
        secondTotalCost = secondPrice * 12; // 12 months
      } else if (secondPackage.packageType == PackageType.weekly) {
        secondTotalCost = secondPrice * 52; // 52 weeks
      } else {
        secondTotalCost = secondPrice;
      }

      // Calculate discount percentage
      if (secondTotalCost > firstTotalCost) {
        final discountPercentage =
            ((secondTotalCost - firstTotalCost) / secondTotalCost * 100)
                .round();
        return 'SAVE $discountPercentage%';
      } else if (firstTotalCost > secondTotalCost) {
        final discountPercentage =
            ((firstTotalCost - secondTotalCost) / firstTotalCost * 100).round();
        return 'SAVE $discountPercentage%';
      }

      return null; // No discount
    } catch (e) {
      debugPrint('Error calculating discount: $e');
      return null;
    }
  }

  Widget _buildPricingPlans() {
    return Column(
      children: [
        for (int i = 0; i < packages.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildPlanCard(
            title: packages[i].storeProduct.title,
            originalPrice: (i == 0 && packages.length >= 2)
                ? "${skuFirst.currencyCode} ${(skuFirst.price * 12).round()}"
                : null,
            currentPrice: (i == 1)
                ? '3 days FREE, then ${skuSecond.priceString}'
                : packages[i].storeProduct.priceString,
            period: packages[i].storeProduct.description.isNotEmpty
                ? packages[i].storeProduct.description
                : (packages[i].packageType == PackageType.weekly
                      ? '/ week'
                      : packages[i].packageType == PackageType.monthly
                      ? '/ month'
                      : 'one time'),
            isSelected: selectedIndex == i,
            badge: (i == 0 && packages.length >= 2)
                ? _calculateDiscountBadge(packages[0], packages[1])
                : null,
            onTap: () {
              setState(() {
                selectedIndex = i;
                freeTrialEnabled =
                    (packages[i].packageType == PackageType.weekly);
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    String? originalPrice,
    required String currentPrice,
    required String period,
    required bool isSelected,
    String? badge,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : isDark
              ? const Color(0xFF2A2A2A)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? Colors.grey.shade600 : theme.dividerColor),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                            // ... (rest of the code)
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: !isDark ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price section
                  if (originalPrice != null) ...[
                    Row(
                      children: [
                        Text(
                          originalPrice,
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentPrice,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'one time',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      '$currentPrice / wk',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                  width: 2,
                ),
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeTrialToggle() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine if free trial is available for the selected plan
    bool isFreeTrialAvailable = false;
    if (packages.isNotEmpty && selectedIndex < packages.length) {
      final selectedPackage = packages[selectedIndex];
      debugPrint(selectedPackage.packageType.toString());

      isFreeTrialAvailable = selectedPackage.packageType == PackageType.weekly;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Free Trial Enabled',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 19,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: isFreeTrialAvailable,
            onChanged: (value) {
              setState(() {
                isFreeTrialAvailable = value;
              });
            },
            activeThumbColor: const Color(0xFFFFFFFF),
            activeTrackColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPurchaseSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Purchase Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : buySubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      freeTrialEnabled && selectedIndex == 1
                          ? 'Start Free Trial'
                          : 'Buy Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          // Manage subscription link
          TextButton(
            onPressed: isLoading
                ? null
                : () async {
                    if (Platform.isAndroid) {
                      if (!await launchUrl(
                        Uri.parse(
                          "https://play.google.com/store/account/subscriptions",
                        ),
                        mode: LaunchMode.externalApplication,
                      )) {
                        throw Exception(
                          'Could not launch subscription management page',
                        );
                      }
                    } else if (Platform.isIOS) {
                      if (!await launchUrl(
                        Uri.parse(
                          "https://apps.apple.com/account/subscriptions",
                        ),
                        mode: LaunchMode.externalApplication,
                      )) {
                        throw Exception(
                          'Could not launch subscription management page',
                        );
                      }
                    }
                  },
            child: Text(
              'Manage Subscription',
              style: TextStyle(
                color: isDark ? Colors.grey : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
