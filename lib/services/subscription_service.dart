import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/revenue_cat_config.dart';

class SubscriptionService extends ChangeNotifier {
  bool _isPremium = false;
  CustomerInfo? _customerInfo;
  int _usageCount = 0;

  static const String _usageCountKey = 'usage_count';
  static const int _freeUsageLimit = 1;

  bool get isPremium => _isPremium;
  CustomerInfo? get customerInfo => _customerInfo;
  int get usageCount => _usageCount;
  int get freeUsageLimit => _freeUsageLimit;
  bool get canUseApp => _isPremium || _usageCount < _freeUsageLimit;

  Future<void> initialize() async {
    try {
      // Configure RevenueCat
      late PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(
          RevenueCatConfig.revCatGoogleKey,
        );
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(RevenueCatConfig.revCatAppleKey);
      }

      await Purchases.configure(configuration);

      await Purchases.enableAdServicesAttributionTokenCollection();

      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Get initial customer info
      await _updateCustomerInfo();

      // Load usage count
      await _loadUsageCount();
    } catch (e) {
      debugPrint('Error initializing RevenueCat: $e');
    }
  }

  Future<void> _loadUsageCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _usageCount = prefs.getInt(_usageCountKey) ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading usage count: $e');
    }
  }

  Future<void> incrementUsageCount() async {
    if (_isPremium) return; // Premium users have unlimited usage

    try {
      _usageCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_usageCountKey, _usageCount);
      notifyListeners();
    } catch (e) {
      debugPrint('Error incrementing usage count: $e');
    }
  }

  Future<void> resetUsageCount() async {
    try {
      _usageCount = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_usageCountKey, 0);
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting usage count: $e');
    }
  }

  Future<void> _updateCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      _isPremium =
          _customerInfo?.entitlements.active.containsKey(
            RevenueCatConfig.premiumEntitlement,
          ) ??
          false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating customer info: $e');
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    _isPremium = customerInfo.entitlements.active.containsKey(
      RevenueCatConfig.premiumEntitlement,
    );
    notifyListeners();
  }

  Future<bool> purchasePremium(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);

      _customerInfo = purchaseResult.customerInfo;
      _isPremium = _customerInfo!.entitlements.active.containsKey(
        RevenueCatConfig.premiumEntitlement,
      );

      notifyListeners();
      return _isPremium;
    } catch (e) {
      debugPrint('Error purchasing premium: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      _isPremium = customerInfo.entitlements.active.containsKey(
        RevenueCatConfig.premiumEntitlement,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  /// Check subscription status
  Future<void> checkSubscriptionStatus() async {
    await _updateCustomerInfo();
  }

  @override
  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    super.dispose();
  }
}
