import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onecall_doctor/models/appointment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onecall_doctor/providers/auth_provider.dart';
import 'package:onecall_doctor/screens/call_screen.dart';
import 'package:onecall_doctor/services/appointment_service.dart';

class AppointmentCard extends ConsumerStatefulWidget {
  final Appointment appointment;
  final VoidCallback? onCheckPrescription;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCheckPrescription,
  });

  @override
  ConsumerState<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends ConsumerState<AppointmentCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final isCompleted = appointment.status == 'completed';
    final isUpcoming = appointment.status == 'upcoming';

    final statusColor =
        isCompleted ? const Color(0xffE8F5E9) : const Color(0xffFFF3E0);
    final statusTextColor =
        isCompleted ? const Color(0xff3A643B) : const Color(0xffE65100);
    final statusText = isCompleted ? "Completed" : "Upcoming";

    final formattedDate =
        DateFormat('EEEE, dd/MM/yyyy').format(appointment.date);
    final displayTime = appointment.time;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.userEmail,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 24),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                displayTime,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Appointment Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Patient Email:', appointment.userEmail),
                  _buildDetailRow(
                      'Consultation Type:', appointment.consultationType),
                  _buildDetailRow('Concern ID:', appointment.concernId),
                  _buildDetailRow('Severity:', '${appointment.severity}/3.0'),
                  _buildDetailRow('Duration:',
                      '${appointment.duration} ${appointment.durationType}'),
                  const SizedBox(height: 16),
                  
                  const SizedBox(height: 16),
                  if (isUpcoming) // Added check
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (isCompleted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Cancel Appointment"),
                            content: const Text(
                                "Are you sure you want to cancel this appointment? \n\nThis will initiate a 100% refund to the patient."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("No"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Close Confirmation
                                  try {
                                    // Show loading
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(child: CircularProgressIndicator()),
                                    );

                                    final user = ref.read(firebaseAuthProvider).currentUser;
                                    final doctorName = user?.displayName ?? "Doctor";

                                    await AppointmentService().cancelAppointment(
                                      appointment.id,
                                      appointment.doctorId,
                                      appointment.patientId,
                                      appointment.price,
                                      appointment.userEmail,
                                      doctorName,
                                      appointment.date,
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context); // Close Loading
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Appointment cancelled. Refund processing.")),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.pop(context); // Close Loading
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Failed to cancel: $e")),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Yes, Cancel"),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Cancel Appointment"),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff3A643B),
                    side: const BorderSide(color: Color(0xff3A643B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(_isExpanded ? "Hide Details" : "View Details"),
                ),
              ),
              if (isUpcoming)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: ElevatedButton(
                      onPressed: () {
                        final user =
                            ref.read(firebaseAuthProvider).currentUser;
                        if (user != null) {
                          final displayName = user.displayName;
                          final userName =
                              (displayName != null && displayName.isNotEmpty)
                                  ? displayName
                                  : "Doctor";

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CallScreen(
                                callId: appointment.id,
                                userId: user.uid,
                                userName: userName,
                                appointment: appointment,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff3A643B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text("Join Call"),
                    ),
                  ),
                ),
            ],
          ),
          if (isCompleted && widget.onCheckPrescription != null) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: widget.onCheckPrescription,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(25),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Write Prescription",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff333333))),
                      ],
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10,),
          Flexible(child: Text(value, textAlign: TextAlign.end,)),
        ],
      ),
    );
  }
}