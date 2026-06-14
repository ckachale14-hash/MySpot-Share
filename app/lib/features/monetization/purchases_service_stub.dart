import 'purchase_package.dart';

/// Web/desktop stub — native in-app purchases aren't available here (web uses the
/// hosted-checkout flow instead). The real implementation is purchases_service_real.dart.
class PurchasesService {
  bool get isSupported => false;
  Future<void> configure() async {}
  Future<void> identify(String uid) async {}
  Future<List<PurchasePackage>> packages() async => const [];
  Future<bool> purchase(String packageId) async => false;
}
