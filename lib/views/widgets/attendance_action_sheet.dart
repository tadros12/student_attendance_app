import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/device_helper.dart';
import '../../models/student_model.dart';
import '../../providers/attendance_providers.dart';

class AttendanceActionSheet extends ConsumerStatefulWidget {
  final Student student;

  const AttendanceActionSheet({super.key, required this.student});

  static Future<void> show(BuildContext context, Student student) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttendanceActionSheet(student: student),
    );
  }

  @override
  ConsumerState<AttendanceActionSheet> createState() => _AttendanceActionSheetState();
}

class _AttendanceActionSheetState extends ConsumerState<AttendanceActionSheet> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _recordAttendance(bool status) async {
    setState(() => _isSubmitting = true);
    final strings = AppStrings.of(context);
    final attendanceService = ref.read(attendanceServiceProvider);

    try {
      final deviceName = await DeviceHelper.getDeviceIdentifier();
      await attendanceService.recordAttendance(
        studentId: widget.student.id,
        status: status,
        notes: _notesController.text.trim(),
        markedBy: deviceName,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  status ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.student.nameEn} • ${status ? strings.attended : strings.absent}',
                  ),
                ),
              ],
            ),
            backgroundColor: status ? Colors.green.shade800 : Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isArabic = strings.isArabic;
    final primaryName = isArabic ? widget.student.nameAr : widget.student.nameEn;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Student Information Header
            Text(
              primaryName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${widget.student.id}  •  ${strings.absencesCount}: ${widget.student.totalAbsences}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Optional Notes Field
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: strings.notes,
                hintText: strings.notesHint,
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 28),

            // Attendance Action Buttons
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  // Attended Button (Green)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _recordAttendance(true),
                      icon: const Icon(Icons.check_circle_rounded, size: 24),
                      label: Text(
                        strings.attended,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Absent Button (Red)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _recordAttendance(false),
                      icon: const Icon(Icons.cancel_rounded, size: 24),
                      label: Text(
                        strings.absent,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
