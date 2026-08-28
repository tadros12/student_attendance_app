import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/localization/app_localizations.dart';
import '../models/attendance_log_model.dart';
import '../models/student_model.dart';
import '../providers/attendance_providers.dart';
import 'widgets/attendance_action_sheet.dart';
import 'widgets/excel_import_dialog.dart';
import 'widgets/qr_view_dialog.dart';
import 'widgets/student_edit_dialog.dart';

class AdminPanelView extends ConsumerStatefulWidget {
  const AdminPanelView({super.key});

  @override
  ConsumerState<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends ConsumerState<AdminPanelView> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final TextEditingController _searchController = TextEditingController();
  String _adminQuery = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final currentDate = ref.read(adminSelectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(adminSelectedDateProvider.notifier).state = picked;
    }
  }

  void _shiftDate(int days) {
    final current = ref.read(adminSelectedDateProvider);
    ref.read(adminSelectedDateProvider.notifier).state = current.add(Duration(days: days));
  }

  void _confirmDelete(BuildContext dialogContext, Student student) {
    final strings = AppStrings.of(dialogContext);
    final isArabic = strings.isArabic;
    final primaryName = isArabic ? student.nameAr : student.nameEn;
    final messenger = ScaffoldMessenger.of(dialogContext);

    showDialog(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Text(strings.deletePerson),
          ],
        ),
        content: Text('${strings.confirmDelete}\n\n• $primaryName (${student.id})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(attendanceServiceProvider).deleteStudent(student.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${strings.personDeleted}: $primaryName'),
                  backgroundColor: Colors.red.shade800,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text(strings.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isArabic = strings.isArabic;

    final selectedDate = ref.watch(adminSelectedDateProvider);
    final selectedDateKey = AttendanceLog.formatDateKey(selectedDate);
    final isToday = AttendanceLog.formatDateKey(DateTime.now()) == selectedDateKey;

    final allStudentsAsync = ref.watch(studentsStreamProvider);
    final dateLogsAsync = ref.watch(adminDateLogsProvider);
    final currentFilter = ref.watch(adminStatusFilterProvider);

    final formattedSelectedDate = DateFormat.yMMMMEEEEd(isArabic ? 'ar' : 'en').format(selectedDate);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Header & Admin Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.admin_panel_settings, color: theme.colorScheme.onPrimaryContainer, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.adminPanel,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            strings.managePeople,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: strings.importExcel,
                      icon: const Icon(Icons.upload_file),
                      onPressed: () => ExcelImportDialog.show(context),
                    ),
                  ],
                ),
              ),
            ),

            // Date Navigation Bar (Day Filter Bar)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      // Previous Day
                      IconButton(
                        tooltip: isArabic ? 'اليوم السابق' : 'Previous Day',
                        icon: Icon(isArabic ? Icons.chevron_right : Icons.chevron_left),
                        onPressed: () => _shiftDate(-1),
                      ),
                      // Date Selector Pill
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _pickDate(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    formattedSelectedDate,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Next Day
                      IconButton(
                        tooltip: isArabic ? 'اليوم التالي' : 'Next Day',
                        icon: Icon(isArabic ? Icons.chevron_left : Icons.chevron_right),
                        onPressed: () => _shiftDate(1),
                      ),
                      // Quick Reset to Today if not on today
                      if (!isToday)
                        TextButton(
                          onPressed: () => ref.read(adminSelectedDateProvider.notifier).state = DateTime.now(),
                          child: Text(strings.today),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Stats for Selected Date
            SliverToBoxAdapter(
              child: allStudentsAsync.maybeWhen(
                data: (students) {
                  final totalPeople = students.length;
                  final dateMap = dateLogsAsync.maybeWhen(data: (map) => map, orElse: () => {});

                  final attendedOnDate = dateMap.values.where((l) => l.status == true).length;
                  final absentOnDate = dateMap.values.where((l) => l.status == false).length;
                  final unmarkedOnDate = (totalPeople - (attendedOnDate + absentOnDate)).clamp(0, totalPeople);

                  return FadeTransition(
                    opacity: CurvedAnimation(parent: _animController, curve: Curves.easeOut),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: strings.filterAttended,
                                  value: '$attendedOnDate',
                                  icon: Icons.check_circle,
                                  color: const Color(0xFF1E8E3E), // Green
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: strings.filterAbsent,
                                  value: '$absentOnDate',
                                  icon: Icons.cancel,
                                  color: const Color(0xFFD93025), // Red
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: strings.filterUnmarked,
                                  value: '$unmarkedOnDate',
                                  icon: Icons.radio_button_unchecked,
                                  color: const Color(0xFF5F6368), // Grey
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: strings.totalPeople,
                                  value: '$totalPeople',
                                  icon: Icons.group,
                                  color: const Color(0xFF1A73E8), // Blue
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: strings.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _adminQuery = v.trim().toLowerCase()),
                ),
              ),
            ),

            // Attendance Filter Chips (All | Attended | Absent | Unmarked)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(strings.filterAll),
                        selected: currentFilter == AttendanceFilterEnum.all,
                        onSelected: (_) => ref.read(adminStatusFilterProvider.notifier).state = AttendanceFilterEnum.all,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        label: Text(strings.filterAttended),
                        selected: currentFilter == AttendanceFilterEnum.attended,
                        onSelected: (_) => ref.read(adminStatusFilterProvider.notifier).state = AttendanceFilterEnum.attended,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.cancel, size: 16, color: Colors.red),
                        label: Text(strings.filterAbsent),
                        selected: currentFilter == AttendanceFilterEnum.absent,
                        onSelected: (_) => ref.read(adminStatusFilterProvider.notifier).state = AttendanceFilterEnum.absent,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.radio_button_unchecked, size: 16),
                        label: Text(strings.filterUnmarked),
                        selected: currentFilter == AttendanceFilterEnum.unmarked,
                        onSelected: (_) => ref.read(adminStatusFilterProvider.notifier).state = AttendanceFilterEnum.unmarked,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // People List for Selected Date
            allStudentsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
              data: (students) {
                final dateMap = dateLogsAsync.maybeWhen(data: (map) => map, orElse: () => {});

                final filtered = students.where((s) {
                  // Text query filter
                  final matchesText = _adminQuery.isEmpty ||
                      s.id.toLowerCase().contains(_adminQuery) ||
                      s.nameEn.toLowerCase().contains(_adminQuery) ||
                      s.nameAr.toLowerCase().contains(_adminQuery);
                  if (!matchesText) return false;

                  // Status filter for chosen date
                  final log = dateMap[s.id];
                  switch (currentFilter) {
                    case AttendanceFilterEnum.attended:
                      return log != null && log.status == true;
                    case AttendanceFilterEnum.absent:
                      return log != null && log.status == false;
                    case AttendanceFilterEnum.unmarked:
                      return log == null;
                    case AttendanceFilterEnum.all:
                      return true;
                  }
                }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(strings.noPeopleFound, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 90, top: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final student = filtered[index];
                        final isArabic = strings.isArabic;
                        final primaryName = isArabic ? student.nameAr : student.nameEn;
                        final secondaryName = isArabic ? student.nameEn : student.nameAr;

                        final log = dateMap[student.id];
                        String dateStatusText;
                        Color dateStatusColor;
                        IconData dateStatusIcon;

                        if (log == null) {
                          dateStatusText = strings.filterUnmarked;
                          dateStatusColor = theme.colorScheme.outline;
                          dateStatusIcon = Icons.radio_button_unchecked;
                        } else if (log.status) {
                          dateStatusText = strings.filterAttended;
                          dateStatusColor = Colors.green.shade700;
                          dateStatusIcon = Icons.check_circle;
                        } else {
                          dateStatusText = strings.filterAbsent;
                          dateStatusColor = Colors.red.shade700;
                          dateStatusIcon = Icons.cancel;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => AttendanceActionSheet.show(context, student),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: theme.colorScheme.primaryContainer,
                                        child: Text(
                                          primaryName.isNotEmpty ? primaryName.characters.first : '#',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              primaryName,
                                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (secondaryName.isNotEmpty && secondaryName != primaryName)
                                              Text(
                                                secondaryName,
                                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                                maxLines: 1,
                                              ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ID: ${student.id}  •  ${strings.absencesCount}: ${student.totalAbsences}',
                                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Action Buttons: QR, Edit, Delete
                                      IconButton(
                                        tooltip: strings.viewQr,
                                        icon: const Icon(Icons.qr_code, size: 20),
                                        color: theme.colorScheme.primary,
                                        onPressed: () => QrViewDialog.show(context, student),
                                      ),
                                      IconButton(
                                        tooltip: strings.edit,
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        onPressed: () => StudentEditDialog.show(context, student),
                                      ),
                                      IconButton(
                                        tooltip: strings.delete,
                                        icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                                        onPressed: () => _confirmDelete(context, student),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Date Status Badge on selected day
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: dateStatusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(dateStatusIcon, size: 13, color: dateStatusColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              dateStatusText,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: dateStatusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (log != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '${strings.markedAt} ${DateFormat.jm(isArabic ? 'ar' : 'en').format(log.date)}',
                                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Log note for that date if exists
                                  if (log?.notes != null && log!.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '${strings.notes}: ${log.notes}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => StudentEditDialog.show(context),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(strings.addPerson),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
