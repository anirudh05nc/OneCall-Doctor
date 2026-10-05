import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onecall_doctor/models/appointment_model.dart';
import 'package:onecall_doctor/widgets/appointment_card.dart';
import 'package:onecall_doctor/providers/auth_provider.dart';
import 'package:onecall_doctor/services/email_service.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'package:onecall_doctor/providers/appointment_provider.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointments"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xff3A643B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xff3A643B),
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          final upcoming = appointments
              .where((a) => a.status == 'upcoming' || a.status == 'accepted')
              .toList();
          final completed =
              appointments.where((a) => a.status == 'completed').toList();
          final cancelled =
              appointments.where((a) => a.status == 'cancelled').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(upcoming, isUpcoming: true),
              _buildList(completed, isUpcoming: false),
              _buildList(cancelled, isUpcoming: false),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildList(List<Appointment> list, {required bool isUpcoming}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          "No appointments found",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final appointment = list[index];
        return AppointmentCard(
          appointment: appointment,
          onCheckPrescription: !isUpcoming
              ? () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final bool hasPrescription =
                          appointment.prescription != null &&
                              appointment.prescription!.isNotEmpty;
                      final TextEditingController prescriptionController =
                          TextEditingController();

                      return StatefulBuilder(
                        builder: (context, setState) {
                          bool isEditing = !hasPrescription;

                          return AlertDialog(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(hasPrescription && !isEditing
                                    ? "Prescription"
                                    : "Write Prescription"),
                                if (hasPrescription && !isEditing)
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        isEditing = true;
                                        prescriptionController.text =
                                            appointment.prescription!;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            content: !isEditing
                                ? SingleChildScrollView(
                                    child: Container(
                                      width: double.maxFinite,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        appointment.prescription!,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  )
                                : TextField(
                                    controller: prescriptionController,
                                    maxLines: 5,
                                    decoration: const InputDecoration(
                                      hintText: "Enter prescription details...",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              if (isEditing)
                                ElevatedButton(
                                  onPressed: () async {
                                    if (prescriptionController.text
                                        .trim()
                                        .isEmpty) {
                                      return;
                                    }
                                    final prescription =
                                        prescriptionController.text.trim();
                                    Navigator.pop(context);

                                    try {
                                      // 1. Update Firestore
                                      await ref
                                          .read(firebaseFirestoreProvider)
                                          .collection('appointments')
                                          .doc(appointment.id)
                                          .update({
                                        'prescription': prescription
                                      });

                                      // 2. Send Email
                                      final user = ref
                                          .read(firebaseAuthProvider)
                                          .currentUser;
                                      final doctorName =
                                          user?.displayName ?? "Doctor";

                                      await EmailService()
                                          .sendPrescriptionEmail(
                                        userEmail: appointment.userEmail,
                                        appointmentId: appointment.id,
                                        doctorName: doctorName,
                                        prescription: prescription,
                                        date: appointment.date
                                            .toString()
                                            .split(
                                                ' ')[0], // Simple date formatting
                                      );

                                      if (context.mounted) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          const CustomSnackBar.success(
                                              message:
                                                  "Prescription sent successfully"),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                              message: "Failed to send: $e"),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text("Submit"),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  );
                }
              : null,
        );
      },
    );
  }
}
