/// Application-wide constants for FairTerms.
library;

class AppConstants {
  AppConstants._();

  /// Base URL for the FairTerms API.
  /// Override at build time: --dart-define=API_BASE_URL=https://api.fairterms.app/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// When true, API error fallbacks return bundled sample data instead of throwing.
  /// Enable at build time: --dart-define=DEBUG_OFFLINE_MODE=true
  static const bool debugOfflineMode =
      bool.fromEnvironment('DEBUG_OFFLINE_MODE');

  /// App name shown throughout the UI.
  static const String appName = 'FairTerms';

  /// App tagline shown on login screen.
  static const String appTagline = 'Detect hidden bias in your payment terms';

  /// Current app version string.
  static const String appVersion = '1.0.0';

  /// Hackathon context description.
  static const String aboutDescription =
      'FairTerms was built to help Indian SMEs detect hidden discrimination '
      'in payment terms imposed by large corporate buyers. Using AI-powered '
      'counterfactual analysis and fairness metrics, we level the playing field.';

  /// Polling interval in seconds for analysis status.
  static const int pollingIntervalSeconds = 3;

  /// Maximum polling duration in seconds before timeout.
  static const int pollingTimeoutSeconds = 180;

  /// Fairness score threshold for "fair" verdict.
  static const int fairScoreThreshold = 71;

  /// Fairness score threshold for "moderate bias" verdict.
  static const int moderateBiasThreshold = 41;

  /// Statistical parity difference threshold for fair result.
  static const double statisticalParityThreshold = 0.1;

  /// Disparate impact ratio fair range lower bound.
  static const double disparateImpactLower = 0.8;

  /// Disparate impact ratio fair range upper bound.
  static const double disparateImpactUpper = 1.2;

  /// Equal opportunity difference threshold for fair result.
  static const double equalOpportunityThreshold = 0.1;

  /// List of all Indian states and union territories.
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    // Union Territories
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  /// Industry options for profile form.
  /// Must match fairness engine seed data industries exactly for peer matching.
  static const List<String> industries = [
    'Auto Components',
    'Chemicals',
    'Electronics',
    'Food Processing',
    'Handicrafts',
    'IT Services',
    'Leather',
    'Metal Fabrication',
    'Pharma',
    'Textiles',
  ];

  /// Buyer type options for payment terms form.
  static const List<String> buyerTypes = [
    'Private Corporation',
    'Public Sector',
    'MNC',
    'Partnership',
    'Other',
  ];

  // Route paths
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeDashboard = '/dashboard';
  static const String routeProfile = '/profile';
  static const String routePaymentTerms = '/payment-terms';
  static const String routeHistory = '/history';
  static const String routeSettings = '/settings';
  static const String routeHeatmap = '/heatmap';
  static const String routeLeaderboard = '/leaderboard';
  static const String routeAdmin = '/admin';
}
