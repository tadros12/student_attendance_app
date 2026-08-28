import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/localization/app_localizations.dart';
import '../models/student_model.dart';
import '../providers/attendance_providers.dart';
import 'scanner_view.dart';
import 'widgets/attendance_action_sheet.dart';
import 'widgets/excel_import_dialog.dart';
import 'widgets/student_card.dart';

class MainDashboardView extends ConsumerWidget {
  const MainDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    final filteredStudents = ref.watch(filteredStudentsProvider);
    final allStudentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Top App Bar & Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Pixel-style Search & Action Bar
                    Row(
                      children: [
                        Expanded(
                          child: SearchBar(
                            elevation: const WidgetStatePropertyAll(0),
                            hintText: strings.searchHint,
                            hintStyle: WidgetStatePropertyAll(
                              theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            leading: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              ref.read(searchQueryProvider.notifier).state = value;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Language Toggle Pill
                        IconButton.filledTonal(
                          tooltip: strings.language,
                          icon: const Icon(Icons.translate),
                          onPressed: () {
                            ref.read(localeProvider.notifier).toggleLocale();
                          },
                        ),
                        // Admin / More Menu
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (value) {
                            if (value == 'import') {
                              ExcelImportDialog.show(context);
                            } else if (value == 'theme') {
                              ref.read(themeModeProvider.notifier).toggleTheme();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'import',
                              child: Row(
                                children: [
                                  const Icon(Icons.upload_file, size: 20),
                                  const SizedBox(width: 12),
                                  Text(strings.importExcel),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'theme',
                              child: Row(
                                children: [
                                  const Icon(Icons.brightness_4, size: 20),
                                  const SizedBox(width: 12),
                                  Text(strings.toggleTheme),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Stats Bar
                    allStudentsAsync.maybeWhen(
                      data: (students) {
                        final totalStudents = students.length;
                        final totalAbsences = students.fold<int>(
                          0,
                          (sum, student) => sum + student.totalAbsences,
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetric(
                                context,
                                label: strings.totalStudents,
                                value: '$totalStudents',
                                icon: Icons.people_alt_outlined,
                              ),
                              Container(height: 28, width: 1, color: Colors.grey.shade400),
                              _buildMetric(
                                context,
                                label: strings.totalAbsences,
                                value: '$totalAbsences',
                                icon: Icons.event_busy_outlined,
                              ),
                            ],
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: allStudentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading local data: $err')),
            data: (_) {
              if (filteredStudents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.noStudentsFound,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 84, top: 4),
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final Student student = filteredStudents[index];
                  return StudentCard(
                    student: student,
                    onTap: () => AttendanceActionSheet.show(context, student),
                  );
                },
              );
            },
          ),
        ),
      ),
      // Floating QR Scanner Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerView()),
          );
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(strings.scanQr),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
