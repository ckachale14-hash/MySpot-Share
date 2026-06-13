/// App-wide constants. Runtime-tunable values (AI quotas, FYP weights, feature
/// flags) belong in Firebase Remote Config, not here.
class AppConfig {
  const AppConfig._();

  static const String appName = 'MySpot';
  static const String tagline = 'Where entrepreneurs share the journey.';

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
