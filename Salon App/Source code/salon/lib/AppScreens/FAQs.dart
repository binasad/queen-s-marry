import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      // Booking & Appointments
      {"q": "How to book an appointment?", "a": "Go to services → choose service → confirm booking."},
      {"q": "Can I cancel my booking?", "a": "Yes, go to My Bookings → select My Appointment → Cancel."},
      {"q": "Do I need to create an account to book?", "a": "Yes, you need to sign up or log in before booking any service."},
      {"q": "Can I reschedule my appointment?", "a": "Yes, go to My Bookings → select the appointment → choose Reschedule."},
      {"q": "Do you offer walk-in services?", "a": "We recommend booking in advance, but walk-ins are welcome if slots are free."},

      // Services & Payments
      {"q": "What payment methods do you accept?", "a": "We accept cash, credit/debit cards, and online payments."},
      {"q": "Do you offer packages or discounts?", "a": "Yes! Check our Offers section for seasonal packages and exclusive discounts."},
      {"q": "Are there any additional charges?", "a": "All charges are shown upfront before confirming your booking."},

      // Salon Policies
      {"q": "What are your timings?", "a": "We are open from 9 AM to 9 PM every day."},
      {"q": "What if I’m running late?", "a": "Please inform us in advance. A grace period of 10 minutes is allowed."},
      {"q": "Do you have a refund policy?", "a": "Cancellations made at least 2 hours before the appointment are fully refundable."},
      {"q": "Do you provide home services?", "a": "Currently, we only offer in-salon services."},

      // App Support
      {"q": "The app isn’t loading properly. What should I do?", "a": "Try clearing cache, updating the app, or checking your internet connection."},
      {"q": "Can I contact support directly?", "a": "Yes, go to Help → Contact Us for phone or chat support."},
      {"q": "How do I update my profile details?", "a": "Go to Profile → Edit Profile to update your name, phone, or email."},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQs", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6CBF), Color(0xFFFFC371)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6CBF), // pink
              Color(0xFFFFC371), // peach
            ],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
          // borderRadius: BorderRadius.only(
          //   topLeft: Radius.circular(60),
          //   topRight: Radius.circular(60),
          // ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: faqs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ExpansionTile(
                    title: Text(
                      faqs[index]['q']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          faqs[index]['a']!,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

