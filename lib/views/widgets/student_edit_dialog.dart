import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/student_model.dart';
import '../../providers/attendance_providers.dart';

class StudentEditDialog extends ConsumerStatefulWidget {
  final Student? student;

  const StudentEditDialog({super.key, this.student});

  static Future<void> show(BuildContext context, [Student? student]) {
    return showDialog(
      context: context,
      builder: (context) => StudentEditDialog(student: student),
    );
  }

  @override
  ConsumerState<StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends ConsumerState<StudentEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;
  late final TextEditingController _absencesController;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  bool get _isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _idController = TextEditingController(text: s?.id ?? '');
    _nameEnController = TextEditingController(text: s?.nameEn ?? '');
    _nameArController = TextEditingController(text: s?.nameAr ?? '');
    _absencesController = TextEditingController(text: '${s?.totalAbsences ?? 0}');
    _notesController = TextEditingController(text: s?.notes ?? '');

    if (!_isEditing && _idController.text.isEmpty) {
      _generateId();
    }
  }

  void _generateId() {
    final rand = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000));
    _idController.text = 'ID-$rand';
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _absencesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final strings = AppStrings.of(context);
    final service = ref.read(attendanceServiceProvider);

    final updated = Student(
      id: _idController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      nameAr: _nameArController.text.trim(),
      totalAbsences: int.tryParse(_absencesController.text.trim()) ?? 0,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    try {
      if (_isEditing) {
        await service.updateStudent(updated);
      } else {
        await service.addStudent(updated);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? strings.personUpdated : strings.personAdded),
            backgroundColor: Colors.green.shade700,
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _isEditing ? Icons.person_outline : Icons.person_add_outlined,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? strings.editPerson : strings.addPerson,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ID
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idController,
                      enabled: !_isEditing,
                      decoration: InputDecoration(
                        labelText: strings.personId,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? strings.fillRequiredFields : null,
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: strings.autoGenerateId,
                      icon: const Icon(Icons.autorenew),
                      onPressed: _generateId,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // English Name
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: strings.personNameEn,
                  prefixIcon: const Icon(Icons.language),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? strings.fillRequiredFields : null,
              ),
              const SizedBox(height: 14),

              // Arabic Name
              TextFormField(
                controller: _nameArController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: strings.personNameAr,
                  prefixIcon: const Icon(Icons.translate),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? strings.fillRequiredFields : null,
              ),
              const SizedBox(height: 14),

              // Absences Count
              TextFormField(
                controller: _absencesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.initialAbsences,
                  prefixIcon: const Icon(Icons.event_busy_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: strings.notes,
                  hintText: strings.notesHint,
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(strings.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(strings.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
