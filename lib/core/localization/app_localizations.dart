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

  // App Navigation & Titles
  String get appTitle => isArabic ? 'نظام تتبع الحضور' : 'Attendance Tracker';
  String get attendance => isArabic ? 'الحضور' : 'Attendance';
  String get adminPanel => isArabic ? 'لوحة التحكم' : 'Admin Panel';
  String get stats => isArabic ? 'نظرة عامة على الإحصائيات' : 'Overview & Stats';
  String get manageStudents => isArabic ? 'إدارة الطلاب' : 'Manage Students';

  // Search & List
  String get searchHint => isArabic ? 'ابحث بالاسم (عربي/إنجليزي) أو الرقم...' : 'Search name (EN/AR) or ID...';
  String get totalStudents => isArabic ? 'إجمالي الطلاب' : 'Total Students';
  String get totalAbsences => isArabic ? 'إجمالي الغياب' : 'Total Absences';
  String get perfectAttendance => isArabic ? 'حضور مثالي (0 غياب)' : 'Perfect Attendance (0)';
  String get avgAbsenceRate => isArabic ? 'متوسط الغياب/طالب' : 'Avg Absences/Student';
  String get absencesCount => isArabic ? 'مرات الغياب' : 'Absences';
  String get noStudentsFound => isArabic ? 'لا يوجد طلاب مطابقين' : 'No students found';

  // Attendance Actions
  String get attended => isArabic ? 'حاضر' : 'Attended';
  String get absent => isArabic ? 'غائب' : 'Not Attended';
  String get markAttendance => isArabic ? 'تسجيل الحضور' : 'Mark Attendance';
  String get notes => isArabic ? 'الملاحظات' : 'Notes';
  String get notesHint => isArabic ? 'أدخل أي ملاحظة سريعة...' : 'Enter a quick note...';
  String get addNote => isArabic ? 'ملاحظة' : 'Add Note';
  String get noteSaved => isArabic ? 'تم حفظ الملاحظة بنجاح' : 'Note saved successfully';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get edit => isArabic ? 'تعديل' : 'Edit';

  // Student CRUD
  String get addStudent => isArabic ? 'إضافة طالب جديد' : 'Add New Student';
  String get editStudent => isArabic ? 'تعديل بيانات الطالب' : 'Edit Student';
  String get deleteStudent => isArabic ? 'حذف الطالب' : 'Delete Student';
  String get confirmDelete => isArabic ? 'هل أنت متأكد من رغبتك في حذف هذا الطالب؟ لا يمكن التراجع عن هذا الإجراء.' : 'Are you sure you want to delete this student? This action cannot be undone.';
  String get studentNameEn => isArabic ? 'الاسم بالإنجليزية' : 'English Name';
  String get studentNameAr => isArabic ? 'الاسم بالعربية' : 'Arabic Name';
  String get studentId => isArabic ? 'كود الطالب (ID)' : 'Student ID / Code';
  String get initialAbsences => isArabic ? 'عدد مرات الغياب' : 'Absence Count';
  String get autoGenerateId => isArabic ? 'توليد تلقائي' : 'Auto Generate';
  String get studentAdded => isArabic ? 'تمت إضافة الطالب بنجاح' : 'Student added successfully';
  String get studentUpdated => isArabic ? 'تم تحديث بيانات الطالب' : 'Student updated successfully';
  String get studentDeleted => isArabic ? 'تم حذف الطالب' : 'Student deleted';
  String get fillRequiredFields => isArabic ? 'يرجى إدخال جميع الحقول المطلوبة' : 'Please fill in all required fields';

  // QR Code
  String get scanQr => isArabic ? 'مسح رمز QR' : 'Scan QR';
  String get viewQr => isArabic ? 'رمز QR' : 'View QR';
  String get qrCodeTitle => isArabic ? 'رمز الاستجابة السريعة للطالب' : 'Student QR Code';
  String get qrInstructions => isArabic ? 'استخدم هذا الرمز للمسح السريع وتسجيل الحضور' : 'Use this code for instant attendance scanning';
  String get studentNotFound => isArabic ? 'لم يتم العثور على الطالب' : 'Student record not found';
  String get attendanceRecorded => isArabic ? 'تم تسجيل الحضور بنجاح' : 'Attendance recorded successfully';

  // Excel & Settings
  String get importExcel => isArabic ? 'استيراد من Excel' : 'Import Excel';
  String get importSuccess => isArabic ? 'تم استيراد بيانات الطلاب بنجاح' : 'Students imported successfully';
  String get selectFile => isArabic ? 'اختر ملف Excel (.xlsx)' : 'Select Excel File (.xlsx)';
  String get parsingFile => isArabic ? 'جاري معالجة الملف والرفع...' : 'Parsing file and uploading...';
  String get toggleTheme => isArabic ? 'تبديل المظهر' : 'Toggle Theme';
  String get language => isArabic ? 'English' : 'العربية';
}
