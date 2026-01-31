import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onecall_doctor/models/appointment_model.dart';
import 'package:onecall_doctor/providers/auth_provider.dart';

final completeAppointmentProvider = FutureProvider.autoDispose.family<void, Appointment>((ref, appointment) async {
  final firestore = ref.watch(firebaseFirestoreProvider);

  // Update appointment status
  final appointmentRef = firestore.collection('appointments').doc(appointment.id);
  final doctorRef = firestore.collection('doctors').doc(appointment.doctorId);

  await firestore.runTransaction((transaction) async {
    // Get the latest doctor data
    final doctorSnapshot = await transaction.get(doctorRef);
    if (!doctorSnapshot.exists) {
      throw Exception("Doctor not found!");
    }

    // Update appointment status
    transaction.update(appointmentRef, {'status': 'completed'});

    // Atomically update doctor's wallet
    transaction.update(doctorRef, {'wallet': FieldValue.increment(appointment.price)});
  });
});

final appointmentsStreamProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  return ref
      .watch(firebaseFirestoreProvider)
      .collection('appointments')
      .where('doctorId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Appointment.fromMap(doc.data(), doc.id))
        .toList();
  });
});
