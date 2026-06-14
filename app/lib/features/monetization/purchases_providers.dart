import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'purchase_package.dart';
import 'purchases_service.dart';

final purchasesServiceProvider =
    Provider<PurchasesService>((_) => PurchasesService());

/// Available IAP packages (empty on web / when RevenueCat isn't configured).
final offeringsProvider = FutureProvider.autoDispose<List<PurchasePackage>>(
  (ref) async {
    final service = ref.watch(purchasesServiceProvider);
    if (!service.isSupported) return const [];
    await service.configure();
    return service.packages();
  },
);
