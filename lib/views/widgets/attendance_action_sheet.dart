import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/device_helper.dart';
import '../../models/attendance_log_model.dart';
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
  AttendanceLog? _existingTodayLog;
  bool _isCheckingExisting = true;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.student.notes ?? '';
    _checkTodayLog();
  }

  Future<void> _checkTodayLog() async {
    final service = ref.read(attendanceServiceProvider);
    final log = await service.getTodayLogForStudent(widget.student.id);
    if (mounted) {
      setState(() {
        _existingTodayLog = log;
        if (log != null && log.notes != null && log.notes!.isNotEmpty) {
          _notesController.text = log.notes!;
        }
        _isCheckingExisting = false;
      });
    }
  }

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
        final primaryName = strings.isArabic ? widget.student.nameAr : widget.student.nameEn;
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
                    '$primaryName • ${status ? strings.attendedToday : strings.absentToday}',
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

    final formattedDate = DateFormat.yMMMMEEEEd(isArabic ? 'ar' : 'en').format(DateTime.now());

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
            const SizedBox(height: 16),

            // Date Pill
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Person Name & ID
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
            const SizedBox(height: 16),

            // Already Marked Notice / Badge (Prevent Duplicate Confusion)
            if (!_isCheckingExisting && _existingTodayLog != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _existingTodayLog!.status
                      ? Colors.green.shade600.withValues(alpha: 0.12)
                      : Colors.red.shade600.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _existingTodayLog!.status ? Colors.green.shade400 : Colors.red.shade400,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _existingTodayLog!.status ? Icons.check_circle : Icons.cancel,
                      color: _existingTodayLog!.status ? Colors.green.shade700 : Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.alreadyMarkedToday,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${strings.markedAt} ${DateFormat.jm(isArabic ? 'ar' : 'en').format(_existingTodayLog!.date)} (${_existingTodayLog!.status ? strings.attended : strings.absent})',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
            const SizedBox(height: 24),

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
