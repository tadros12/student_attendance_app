import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/student_model.dart';

class QrViewDialog extends StatelessWidget {
  final Student student;

  const QrViewDialog({super.key, required this.student});

  static Future<void> show(BuildContext context, Student student) {
    return showDialog(
      context: context,
      builder: (context) => QrViewDialog(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isArabic = strings.isArabic;
    final primaryName = isArabic ? student.nameAr : student.nameEn;
    final secondaryName = isArabic ? student.nameEn : student.nameAr;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.qr_code_2, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.qrCodeTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // QR Code Container with subtle white background for contrast
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: student.id,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Student Info
            Text(
              primaryName,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (secondaryName.isNotEmpty && secondaryName != primaryName)
              Text(
                secondaryName,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),

            // ID Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ID: ${student.id}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(strings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
