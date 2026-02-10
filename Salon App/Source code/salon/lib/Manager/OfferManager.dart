class OfferManager {
  static List<Map<String, String>> offers = [];

  static void addOffer({
    required String title,
    required String discount,
    required String image,
    String duration = "Limited",
  }) {
    offers.add({
      "title": title,
      "discount": discount,
      "image": image,
      "duration": duration,
    });
  }

  static void clearOffers() {
    offers.clear();
  }
}
