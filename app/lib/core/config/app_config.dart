/// App-wide constants. Runtime-tunable values (AI quotas, FYP weights, feature
/// flags) belong in Firebase Remote Config, not here.
class AppConfig {
  const AppConfig._();

  static const String appName = 'MySpot';
  static const String tagline = 'Where entrepreneurs share the journey.';

  /// Hosted legal documents (sources in docs/legal). Stores require both to be
  /// publicly reachable — replace with your hosted URLs before submission.
  static const String privacyUrl = 'https://myspotshare.com/privacy';
  static const String termsUrl = 'https://myspotshare.com/terms';

  /// RevenueCat public SDK keys (safe to ship). Set from the RevenueCat dashboard;
  /// leave as REPLACE_* to disable in-app purchases until configured.
  static const String revenueCatIosKey = 'REPLACE_WITH_REVENUECAT_IOS_KEY';
  static const String revenueCatAndroidKey = 'REPLACE_WITH_REVENUECAT_ANDROID_KEY';

  /// Industry categories — drive FYP, "People You May Know", and the directory.
  static const List<String> industries = <String>[
    'Technology',
    'Retail & E-commerce',
    'Food & Beverage',
    'Finance',
    'Health & Wellness',
    'Education',
    'Real Estate',
    'Manufacturing',
    'Media & Content',
    'Professional Services',
    'Other',
  ];
}
