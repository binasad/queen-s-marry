class Appointment {
  final String serviceName;
  final String name;
  final String date;
  final String time;
  final String phone;

  Appointment({
    required this.serviceName,
    required this.name,
    required this.date,
    required this.time,
    required this.phone,
  });
}

class AppointmentManager {
  static final List<Appointment> _appointments = [];

  static void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
  }

  static List<Appointment> get appointments => _appointments;
}
