import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/localization/app_localizations.dart';
import '../models/student_model.dart';
import '../providers/attendance_providers.dart';
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
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
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
    final allStudentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header & Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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

            // Googly Animated Stats Grid
            SliverToBoxAdapter(
              child: allStudentsAsync.maybeWhen(
                data: (students) {
                  final total = students.length;
                  final totalAbsences = students.fold<int>(0, (sum, s) => sum + s.totalAbsences);
                  final perfectCount = students.where((s) => s.totalAbsences == 0).length;
                  final avgAbsences = total > 0 ? (totalAbsences / total).toStringAsFixed(1) : '0';

                  return FadeTransition(
                    opacity: CurvedAnimation(parent: _animController, curve: Curves.easeOut),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: strings.totalPeople,
                                  value: '$total',
                                  icon: Icons.people_alt,
                                  color: const Color(0xFF1A73E8), // Google Blue
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: strings.totalAbsences,
                                  value: '$totalAbsences',
                                  icon: Icons.event_busy,
                                  color: const Color(0xFFD93025), // Google Red
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
                                  title: strings.perfectAttendance,
                                  value: '$perfectCount',
                                  icon: Icons.verified_user,
                                  color: const Color(0xFF1E8E3E), // Google Green
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: strings.avgAbsenceRate,
                                  value: avgAbsences,
                                  icon: Icons.analytics_outlined,
                                  color: const Color(0xFFF9AB00), // Google Amber
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

            // Section Title & Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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

            // People Manage List
            allStudentsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
              data: (students) {
                final filtered = students.where((s) {
                  if (_adminQuery.isEmpty) return true;
                  return s.id.toLowerCase().contains(_adminQuery) ||
                      s.nameEn.toLowerCase().contains(_adminQuery) ||
                      s.nameAr.toLowerCase().contains(_adminQuery);
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

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                            child: Row(
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
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
                    fontSize: 18,
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
