import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/student_model.dart';
import 'quick_note_dialog.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isArabic = strings.isArabic;

    final primaryName = isArabic ? student.nameAr : student.nameEn;
    final secondaryName = isArabic ? student.nameEn : student.nameAr;

    Color absenceBadgeColor;
    if (student.totalAbsences == 0) {
      absenceBadgeColor = Colors.green.shade600;
    } else if (student.totalAbsences <= 2) {
      absenceBadgeColor = Colors.orange.shade700;
    } else {
      absenceBadgeColor = Colors.red.shade700;
    }

    final hasNote = student.notes != null && student.notes!.trim().isNotEmpty;

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
                  // Avatar with Student Initials
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

                  // Student Info
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

                  // Quick Note Button next to student
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

              // Note preview if present
              if (hasNote) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          student.notes!,
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
