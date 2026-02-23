import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  static const Color brandPink = Color(0xFFFF0068);
  static const Color deepCharcoal = Color(0xFF1A1A2E);
  static const Color warmWhite = Color(0xFFFAFAFC);

  final List<Map<String, String>> _faqs = [
    {"q": "How to book an appointment?", "a": "Go to services → choose service → confirm booking."},
    {"q": "Can I cancel my booking?", "a": "Yes, go to My Bookings → select My Appointment → Cancel."},
    {"q": "Do I need to create an account to book?", "a": "Yes, you need to sign up or log in before booking any service."},
    {"q": "Can I reschedule my appointment?", "a": "Yes, go to My Bookings → select the appointment → choose Reschedule."},
    {"q": "Do you offer walk-in services?", "a": "We recommend booking in advance, but walk-ins are welcome if slots are free."},
    {"q": "What payment methods do you accept?", "a": "We accept cash, credit/debit cards, and online payments."},
    {"q": "Do you offer packages or discounts?", "a": "Yes! Check our Offers section for seasonal packages and exclusive discounts."},
    {"q": "Are there any additional charges?", "a": "All charges are shown upfront before confirming your booking."},
    {"q": "What are your timings?", "a": "We are open from 9 AM to 9 PM every day."},
    {"q": "What if I'm running late?", "a": "Please inform us in advance. A grace period of 10 minutes is allowed."},
    {"q": "Do you have a refund policy?", "a": "Cancellations made at least 2 hours before the appointment are fully refundable."},
    {"q": "Do you provide home services?", "a": "Currently, we only offer in-salon services."},
    {"q": "The app isn't loading properly. What should I do?", "a": "Try clearing cache, updating the app, or checking your internet connection."},
    {"q": "Can I contact support directly?", "a": "Yes, go to Help → Contact Us for phone or chat support."},
    {"q": "How do I update my profile details?", "a": "Go to Profile → Edit Profile to update your name, phone, or email."},
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmWhite,
      appBar: AppBar(
        title: const Text(
          "FAQs",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: deepCharcoal,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: deepCharcoal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: warmWhite,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: ListView.separated(
            itemCount: _faqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final isExpanded = _expandedIndex == index;
              return _buildFAQItem(index, isExpanded);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(int index, bool isExpanded) {
    final faq = _faqs[index];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? brandPink.withOpacity(0.2) : Colors.black.withOpacity(0.04),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isExpanded ? 20 : 12,
            offset: Offset(0, isExpanded ? 6 : 4),
            spreadRadius: isExpanded ? 0 : 0,
          ),
          if (isExpanded)
            BoxShadow(
              color: brandPink.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _expandedIndex = isExpanded ? null : index;
          }),
          borderRadius: BorderRadius.circular(16),
          splashColor: brandPink.withOpacity(0.08),
          highlightColor: brandPink.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: brandPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CupertinoIcons.question_circle_fill,
                        color: brandPink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        faq['q']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: deepCharcoal,
                          height: 1.4,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade500,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16, left: 42),
                    child: Text(
                      faq['a']!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
