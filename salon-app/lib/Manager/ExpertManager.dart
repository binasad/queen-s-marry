class ExpertManager {
  static List<Map<String, String>> experts = [];

  static void addExpert({
    required String name,
    required String specialty, // <-- matches your call
    required String image,
    String experience = "1 year",
  }) {
    experts.add({
      "name": name,
      "specialty": specialty,
      "image": image,
      "experience": experience,
    });
  }

  static void clearExperts() {
    experts.clear();
  }
}
