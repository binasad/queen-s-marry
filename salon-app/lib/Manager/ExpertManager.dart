class ExpertManager {
  static List<Map<String, String>> experts = [
    {
      "name": "Alice Smith",
      "specialty": "Hair Stylist",
      "image": "assets/dummy_expert1.jpg",
      "experience": "5 years",
    },
    {
      "name": "Bob Johnson",
      "specialty": "Nail Artist",
      "image": "assets/dummy_expert2.jpg",
      "experience": "3 years",
    },
    {
      "name": "Carol Lee",
      "specialty": "Makeup Artist",
      "image": "assets/dummy_expert3.jpg",
      "experience": "4 years",
    },
  ];

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
