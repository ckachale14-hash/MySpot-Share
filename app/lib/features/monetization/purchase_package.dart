/// A purchasable plan, abstracted from the RevenueCat types so the web stub and
/// the premium screen don't depend on the native SDK.
class PurchasePackage {
  const PurchasePackage({
    required this.id,
    required this.title,
    required this.priceString,
    required this.plan,
  });

  final String id;
  final String title;
  final String priceString;
  final String plan; // pro | business
}
