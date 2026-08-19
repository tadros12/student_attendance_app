import 'package:flutter/material.dart';

enum AppLanguage { english, arabic }

class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  bool get isArabic => locale.languageCode == 'ar';

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(locale);
  }

  // App Strings
  String get appTitle => isArabic ? 'نظام تتبع الحضور' : 'Attendance Tracker';
  String get searchHint => isArabic ? 'ابحث بالاسم (عربي/إنجليزي) أو الرقم...' : 'Search name (EN/AR) or ID...';
  String get totalStudents => isArabic ? 'إجمالي الطلاب' : 'Total Students';
  String get totalAbsences => isArabic ? 'إجمالي الغياب' : 'Total Absences';
  String get absencesCount => isArabic ? 'مرات الغياب' : 'Absences';
  String get attended => isArabic ? 'حاضر' : 'Attended';
  String get absent => isArabic ? 'غائب' : 'Not Attended';
  String get markAttendance => isArabic ? 'تسجيل الحضور' : 'Mark Attendance';
  String get notes => isArabic ? 'ملاحظات (اختياري)' : 'Notes (Optional)';
  String get notesHint => isArabic ? 'أدخل أي ملاحظات إضافية...' : 'Enter any notes...';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get scanQr => isArabic ? 'مسح رمز QR' : 'Scan QR Code';
  String get importExcel => isArabic ? 'استيراد من Excel' : 'Import Excel';
  String get studentNotFound => isArabic ? 'لم يتم العثور على الطالب' : 'Student record not found';
  String get attendanceRecorded => isArabic ? 'تم تسجيل الحضور بنجاح' : 'Attendance recorded successfully';
  String get syncStatusOffline => isArabic ? 'يعمل دون اتصال (سيتزامن لاحقاً)' : 'Offline mode (will sync automatically)';
  String get importSuccess => isArabic ? 'تم استيراد بيانات الطلاب بنجاح' : 'Students imported successfully';
  String get selectFile => isArabic ? 'اختر ملف Excel (.xlsx)' : 'Select Excel File (.xlsx)';
  String get parsingFile => isArabic ? 'جاري معالجة الملف والرفع...' : 'Parsing file and uploading...';
  String get noStudentsFound => isArabic ? 'لا يوجد طلاب مطابقين' : 'No students found';
  String get adminOptions => isArabic ? 'خيارات الإدارة' : 'Admin Tools';
  String get toggleTheme => isArabic ? 'تبديل المظهر' : 'Toggle Theme';
  String get language => isArabic ? 'English' : 'العربية';
}
