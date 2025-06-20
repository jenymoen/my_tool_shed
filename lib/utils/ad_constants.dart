class AdConstants {
  // Test ad unit IDs (for development)
  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // Production ad unit IDs
  static const String dashboardBannerAdUnitId =
      'ca-app-pub-5326232965412305/9406053435';
  static const String toolsBannerAdUnitId =
      'ca-app-pub-5326232965412305/9406053435';
  static const String communityBannerAdUnitId =
      'ca-app-pub-5326232965412305/9406053435';
  static const String profileBannerAdUnitId =
      'ca-app-pub-5326232965412305/9406053435';
  static const String settingsBannerAdUnitId =
      'ca-app-pub-5326232965412305/9406053435';

  // Helper method to get the appropriate ad unit ID based on build mode
  static String getAdUnitId(String productionId, {bool isDebug = false}) {
    return isDebug ? testBannerAdUnitId : productionId;
  }
}
