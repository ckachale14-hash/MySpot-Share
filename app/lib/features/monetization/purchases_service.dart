// Exposes [PurchasesService] — RevenueCat IAP on mobile (dart.library.io), a
// no-op stub on web. The premium screen and main bootstrap import this barrel only.
export 'purchases_service_stub.dart'
    if (dart.library.io) 'purchases_service_real.dart';
