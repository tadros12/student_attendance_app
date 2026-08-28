import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/attendance_log_model.dart';
import '../../models/student_model.dart';
import '../../providers/attendance_providers.dart';
import 'quick_note_dialog.dart';

class StudentCard extends ConsumerWidget {
  final Student student;
  final VoidCallback onTap;

  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isArabic = strings.isArabic;

    final primaryName = isArabic ? student.nameAr : student.nameEn;
    final secondaryName = isArabic ? student.nameEn : student.nameAr;

    final todayMapAsync = ref.watch(todayAttendanceMapProvider);
    final AttendanceLog? todayLog = todayMapAsync.maybeWhen(
      data: (map) => map[student.id],
      orElse: () => null,
    );

    // Absence Badge Color
    Color absenceBadgeColor;
    if (student.totalAbsences == 0) {
      absenceBadgeColor = Colors.green.shade600;
    } else if (student.totalAbsences <= 2) {
      absenceBadgeColor = Colors.orange.shade700;
    } else {
      absenceBadgeColor = Colors.red.shade700;
    }

    // Today's Status Details
    String todayStatusText;
    Color todayStatusColor;
    IconData todayStatusIcon;

    if (todayLog == null) {
      todayStatusText = strings.unmarkedToday;
      todayStatusColor = theme.colorScheme.outline;
      todayStatusIcon = Icons.radio_button_unchecked;
    } else if (todayLog.status) {
      todayStatusText = strings.attendedToday;
      todayStatusColor = Colors.green.shade700;
      todayStatusIcon = Icons.check_circle;
    } else {
      todayStatusText = strings.absentToday;
      todayStatusColor = Colors.red.shade700;
      todayStatusIcon = Icons.cancel;
    }

    final todayNote = todayLog?.notes;
    final studentNote = student.notes;
    final hasNote = (studentNote != null && studentNote.trim().isNotEmpty) ||
        (todayNote != null && todayNote.trim().isNotEmpty);
    final displayNote = (todayNote != null && todayNote.trim().isNotEmpty)
        ? todayNote
        : (studentNote ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar with Initials
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      primaryName.isNotEmpty ? primaryName.characters.first : '#',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Person Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (secondaryName.isNotEmpty && secondaryName != primaryName)
                          Text(
                            secondaryName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${student.id}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.outline,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Note Button
                  IconButton(
                    tooltip: strings.addNote,
                    icon: Icon(
                      hasNote ? Icons.sticky_note_2 : Icons.note_add_outlined,
                      color: hasNote ? theme.colorScheme.primary : theme.colorScheme.outline,
                      size: 22,
                    ),
                    onPressed: () => QuickNoteDialog.show(context, student),
                  ),

                  const SizedBox(width: 4),

                  // Absence Count Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: absenceBadgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${student.totalAbsences}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: absenceBadgeColor,
                          ),
                        ),
                        Text(
                          strings.absencesCount,
                          style: TextStyle(
                            fontSize: 9,
                            color: absenceBadgeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Today's Status Banner Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: todayStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(todayStatusIcon, size: 14, color: todayStatusColor),
                    const SizedBox(width: 6),
                    Text(
                      todayStatusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: todayStatusColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Note preview if present
              if (hasNote) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          displayNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
