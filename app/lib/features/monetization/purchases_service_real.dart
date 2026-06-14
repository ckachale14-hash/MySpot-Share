import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config/app_config.dart';
import 'purchase_package.dart';

/// Mobile in-app purchases via RevenueCat (StoreKit / Play Billing). Required for
/// in-app digital goods on the App/Play stores. Entitlement grants are confirmed
/// server-side by the revenueCatWebhook.
class PurchasesService {
  bool _configured = false;
  bool get isSupported => true;

  Future<void> configure() async {
    if (_configured) return;
    final key = defaultTargetPlatform == TargetPlatform.iOS
        ? AppConfig.revenueCatIosKey
        : AppConfig.revenueCatAndroidKey;
    if (key.isEmpty || key.startsWith('REPLACE')) return; // not configured yet
    await Purchases.configure(PurchasesConfiguration(key));
    _configured = true;
  }

  Future<void> identify(String uid) async {
    if (!_configured) return;
    await Purchases.logIn(uid);
  }

  Future<List<PurchasePackage>> packages() async {
    if (!_configured) return const [];
    final offerings = await Purchases.getOfferings();
    final pkgs = offerings.current?.availablePackages ?? const [];
    return [
      for (final p in pkgs)
        PurchasePackage(
          id: p.identifier,
          title: p.storeProduct.title,
          priceString: p.storeProduct.priceString,
          plan: p.identifier.toLowerCase().contains('business') ? 'business' : 'pro',
        ),
    ];
  }

  Future<bool> purchase(String packageId) async {
    if (!_configured) return false;
    final offerings = await Purchases.getOfferings();
    final pkgs = offerings.current?.availablePackages ?? const [];
    Package? target;
    for (final p in pkgs) {
      if (p.identifier == packageId) {
        target = p;
        break;
      }
    }
    if (target == null) return false;
    final customerInfo = await Purchases.purchasePackage(target);
    return customerInfo.entitlements.active.containsKey('premium');
  }
}
