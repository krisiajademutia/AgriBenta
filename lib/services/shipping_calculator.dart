class ShippingCalculator {
  static double calculateSurcharge({
    required String buyerCity,
    required String buyerProvince,
    required String buyerRegion,
    required String sellerLocationString,
  }) {
    // 1. Parse Seller Location
    // Expected: "Region, Province, City, Brgy"
    List<String> sellerParts = sellerLocationString
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .toList();

    String sellerRegion = sellerParts.isNotEmpty ? sellerParts[0] : '';
    String sellerProvince = sellerParts.length >= 2 ? sellerParts[1] : '';
    String sellerCity = sellerParts.length >= 3 ? sellerParts[2] : '';

    // 2. Compare (The Zone Logic)
    if (buyerCity.toLowerCase() == sellerCity) {
      return 0.0; // Zone A
    } else if (buyerProvince.toLowerCase() == sellerProvince) {
      return 250.0; // Zone B
    } else if (buyerRegion.toLowerCase() == sellerRegion) {
      return 800.0; // Zone C
    } else {
      return 2000.0; // Zone D
    }
  }

  static String getLabel(double surcharge) {
    if (surcharge == 0.0) return "Standard Local Delivery";
    if (surcharge == 250.0) return "Inter-City Fee (+₱250)";
    if (surcharge == 800.0) return "Regional Trucking (+₱800)";
    return "Cross-Region Logistics (+₱2,000)";
  }
}
