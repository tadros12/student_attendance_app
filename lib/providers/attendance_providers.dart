import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/arabic_normalizer.dart';
import '../models/student_model.dart';
import '../services/excel_service.dart';
import '../services/firestore_service.dart';

// Services
final isFirebaseInitializedProvider = StateProvider<bool>((ref) => false);

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize via ProviderScope overrides in main');
});

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final isFirebaseReady = ref.watch(isFirebaseInitializedProvider);
  return AttendanceService(
    prefs: prefs,
    isFirebaseReady: isFirebaseReady,
  );
});

final excelServiceProvider = Provider<ExcelService>((ref) {
  return ExcelService();
});

// App Settings: Locale & Theme
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  LocaleNotifier(this._prefs)
      : super(Locale(_prefs.getString(AppConstants.prefLocaleKey) ?? 'en'));

  void toggleLocale() {
    final next = state.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    state = next;
    _prefs.setString(AppConstants.prefLocaleKey, next.languageCode);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs)
      : super(ThemeMode.values[_prefs.getInt(AppConstants.prefThemeModeKey) ?? ThemeMode.system.index]);

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    _prefs.setInt(AppConstants.prefThemeModeKey, next.index);
  }
}

// Student Stream
final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  final service = ref.watch(attendanceServiceProvider);
  return service.getStudentsStream();
});

// Search Query State
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Students Provider (Bilingual + ID Substring Search)
final filteredStudentsProvider = Provider<List<Student>>((ref) {
  final studentsAsync = ref.watch(studentsStreamProvider);
  final query = ref.watch(searchQueryProvider).trim();

  return studentsAsync.maybeWhen(
    data: (students) {
      if (query.isEmpty) return students;

      final normalizedQuery = ArabicNormalizer.normalize(query);
      final lowerQuery = query.toLowerCase();

      return students.where((student) {
        final matchesId = student.id.toLowerCase().contains(lowerQuery);
        final matchesEn = student.nameEn.toLowerCase().contains(lowerQuery);
        final matchesAr = ArabicNormalizer.normalize(student.nameAr).contains(normalizedQuery);

        return matchesId || matchesEn || matchesAr;
      }).toList();
    },
    orElse: () => [],
  );
});
