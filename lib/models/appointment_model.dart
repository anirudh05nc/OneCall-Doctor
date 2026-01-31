import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String concernId;
  final String doctorId;
  final String consultationType;
  final DateTime date;
  final String time;
  final double severity;
  final String duration;
  final String durationType;
  final String status;
  final String userEmail;
  final String doctorEmail;
  final double price;
  final String? prescription;
  final String? cancelledBy; // Added
  final DateTime createdAt; // Added

  Appointment({
    required this.id,
    required this.patientId,
    required this.concernId,
    required this.doctorId,
    required this.consultationType,
    required this.date,
    required this.time,
    required this.severity,
    required this.duration,
    required this.durationType,
    required this.userEmail,
    required this.doctorEmail,
    required this.status,
    required this.price,
    this.prescription,
    this.cancelledBy, // Added
    required this.createdAt, // Added
  });

  factory Appointment.fromMap(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      patientId: data['patientId'] ?? '',
      concernId: data['concernId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      consultationType: data['consultationType'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      severity: (data['severity'] ?? 0.0).toDouble(),
      duration: data['duration'] ?? '',
      durationType: data['durationType'] ?? '',
      status: data['status'] ?? 'upcoming',
      userEmail: data['userEmail'] ?? '',
      doctorEmail: data['doctorEmail'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      prescription: data['prescription'],
      cancelledBy: data['cancelledBy'], // Added
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['date'] as Timestamp).toDate(), // Fallback to date
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'concernId': concernId,
      'doctorId': doctorId,
      'consultationType': consultationType,
      'date': Timestamp.fromDate(date),
      'time': time,
      'severity': severity,
      'duration': duration,
      'durationType': durationType,
      'status': status,
      'userEmail': userEmail,
      'doctorEmail': doctorEmail,
      'price': price,
      'prescription': prescription,
      'cancelledBy': cancelledBy, // Added
      'createdAt': Timestamp.fromDate(createdAt), // Added
    };
  }
}
