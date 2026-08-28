import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/attendance_providers.dart';

class ExcelImportDialog extends ConsumerStatefulWidget {
  const ExcelImportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ExcelImportDialog(),
    );
  }

  @override
  ConsumerState<ExcelImportDialog> createState() => _ExcelImportDialogState();
}

class _ExcelImportDialogState extends ConsumerState<ExcelImportDialog> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _importFile() async {
    final strings = AppStrings.of(context);
    final excelService = ref.read(excelServiceProvider);
    final attendanceService = ref.read(attendanceServiceProvider);

    try {
      final File? file = await excelService.pickExcelFile();
      if (file == null) return;

      setState(() {
        _isLoading = true;
        _statusMessage = strings.parsingFile;
      });

      final students = await excelService.parseStudentsFromExcel(file);

      if (students.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid student rows found in Excel sheet.')),
          );
        }
        return;
      }

      final count = await attendanceService.batchUploadStudents(students);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.importSuccess} ($count)'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.table_chart_outlined, color: Colors.green),
          const SizedBox(width: 12),
          Text(strings.importExcel),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.isArabic
                ? 'قم باختيار ملف Excel يحتوي على الأعمدة التالية:\n• كود الطالب (ID)\n• الاسم بالإنجليزية (name_en)\n• الاسم بالعربية (name_ar)\n• الغياب (اختياري)'
                : 'Select an Excel file with the following columns:\n• Student ID\n• English Name (name_en)\n• Arabic Name (name_ar)\n• Absences (optional)',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            Center(child: Text(_statusMessage, style: theme.textTheme.bodySmall)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _importFile,
          icon: const Icon(Icons.file_open_outlined),
          label: Text(strings.selectFile),
        ),
      ],
    );
  }
}
