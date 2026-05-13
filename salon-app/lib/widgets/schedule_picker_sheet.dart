import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _kPrimary = Color(0xFFFF0068);

/// Shared schedule picker bottom sheet used by:
///   • Service detail → Add to Cart  (no initial values)
///   • Cart screen → Edit schedule    (pre-fills current values)
///
/// Returns a `ScheduleSelection` (date `yyyy-MM-dd` + 12-hour time label) on
/// confirm, or null on cancel.
class ScheduleSelection {
  final String date; // yyyy-MM-dd
  final String time; // e.g. "10:00 am"
  const ScheduleSelection({required this.date, required this.time});
}

const List<String> kDefaultTimeSlots = [
  '9:00 am', '10:00 am', '11:00 am', '12:00 pm',
  '2:00 pm', '3:00 pm', '4:00 pm', '5:00 pm',
];

Future<ScheduleSelection?> showSchedulePickerSheet(
  BuildContext context, {
  String? initialDate,
  String? initialTime,
  String title = 'Schedule',
  String subtitle = 'Pick a date and time slot',
  String confirmLabel = 'Save schedule',
  List<String> timeSlots = kDefaultTimeSlots,
}) {
  return showModalBottomSheet<ScheduleSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      String? pickedDate = initialDate;
      String? pickedTime = initialTime;
      final dates = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

      return StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 88,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dates.length,
                    itemBuilder: (_, i) {
                      final d = dates[i];
                      final dStr = DateFormat('yyyy-MM-dd').format(d);
                      final selected = pickedDate == dStr;
                      return GestureDetector(
                        onTap: () => setSheet(() => pickedDate = dStr),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 64,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: selected ? _kPrimary : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('EEE').format(d),
                                  style: TextStyle(
                                    color: selected ? Colors.white70 : Colors.grey[600],
                                    fontSize: 11,
                                  )),
                              const SizedBox(height: 2),
                              Text(DateFormat('d').format(d),
                                  style: TextStyle(
                                    color: selected ? Colors.white : Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Time Slot',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: timeSlots.map((s) {
                    final selected = pickedTime == s;
                    return GestureDetector(
                      onTap: () => setSheet(() => pickedTime = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? _kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? _kPrimary : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: (pickedDate == null || pickedTime == null)
                        ? null
                        : () => Navigator.pop(
                              ctx,
                              ScheduleSelection(date: pickedDate!, time: pickedTime!),
                            ),
                    child: Text(confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}
