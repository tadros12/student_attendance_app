import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/localization/app_localizations.dart';
import '../models/student_model.dart';
import '../providers/attendance_providers.dart';
import 'admin_panel_view.dart';
import 'scanner_view.dart';
import 'widgets/attendance_action_sheet.dart';
import 'widgets/excel_import_dialog.dart';
import 'widgets/student_card.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainDashboardView extends ConsumerWidget {
  const MainDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          _AttendanceHomeTab(),
          AdminPanelView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          ref.read(navigationIndexProvider.notifier).state = idx;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.co_present_outlined),
            selectedIcon: const Icon(Icons.co_present),
            label: strings.attendance,
          ),
          NavigationDestination(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: const Icon(Icons.admin_panel_settings),
            label: strings.adminPanel,
          ),
        ],
      ),
    );
  }
}

class _AttendanceHomeTab extends ConsumerWidget {
  const _AttendanceHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isArabic = strings.isArabic;

    final filteredStudents = ref.watch(filteredStudentsProvider);
    final allStudentsAsync = ref.watch(studentsStreamProvider);
    final todayMapAsync = ref.watch(todayAttendanceMapProvider);

    final formattedToday = DateFormat.yMMMMEEEEd(isArabic ? 'ar' : 'en').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Top App Bar, Date Banner & Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search & Action Bar
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
                        // More Menu
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
                    const SizedBox(height: 10),

                    // Today's Date Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            formattedToday,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Stats Bar (Today's Attendance Stats)
                    allStudentsAsync.maybeWhen(
                      data: (students) {
                        final totalPeople = students.length;
                        final todayMap = todayMapAsync.maybeWhen(
                          data: (map) => map,
                          orElse: () => {},
                        );

                        final attendedToday = todayMap.values.where((l) => l.status == true).length;
                        final absentToday = todayMap.values.where((l) => l.status == false).length;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetric(
                                context,
                                label: strings.attendedToday,
                                value: '$attendedToday',
                                icon: Icons.check_circle_outline,
                                color: Colors.green.shade700,
                              ),
                              Container(height: 24, width: 1, color: Colors.grey.shade400),
                              _buildMetric(
                                context,
                                label: strings.absentToday,
                                value: '$absentToday',
                                icon: Icons.cancel_outlined,
                                color: Colors.red.shade700,
                              ),
                              Container(height: 24, width: 1, color: Colors.grey.shade400),
                              _buildMetric(
                                context,
                                label: strings.totalPeople,
                                value: '$totalPeople',
                                icon: Icons.group_outlined,
                                color: theme.colorScheme.primary,
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
            error: (err, _) => Center(child: Text('Error loading data: $err')),
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
                        strings.noPeopleFound,
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
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
