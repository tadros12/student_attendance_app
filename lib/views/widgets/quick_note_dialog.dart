import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/student_model.dart';
import '../../providers/attendance_providers.dart';

class QuickNoteDialog extends ConsumerStatefulWidget {
  final Student student;

  const QuickNoteDialog({super.key, required this.student});

  static Future<void> show(BuildContext context, Student student) {
    return showDialog(
      context: context,
      builder: (context) => QuickNoteDialog(student: student),
    );
  }

  @override
  ConsumerState<QuickNoteDialog> createState() => _QuickNoteDialogState();
}

class _QuickNoteDialogState extends ConsumerState<QuickNoteDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.student.notes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _isSaving = true);
    final strings = AppStrings.of(context);
    final service = ref.read(attendanceServiceProvider);

    try {
      await service.updateStudentNotes(widget.student.id, _controller.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.noteSaved),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isArabic = strings.isArabic;
    final primaryName = isArabic ? widget.student.nameAr : widget.student.nameEn;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          Icon(Icons.edit_note, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${strings.notes}: $primaryName',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: strings.notesHint,
          prefixIcon: const Icon(Icons.sticky_note_2_outlined),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveNote,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(strings.save),
        ),
      ],
    );
  }
}
