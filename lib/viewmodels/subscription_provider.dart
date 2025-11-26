import 'package:flutter_riverpod/legacy.dart';

import '../services/subscription_service.dart';

final subscriptionProvider = ChangeNotifierProvider<SubscriptionService>((ref) {
  final service = SubscriptionService();
  service.initialize();
  return service;
});
