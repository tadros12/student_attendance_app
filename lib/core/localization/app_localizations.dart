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
  String get appTitle => isArabic ? 'نظام تسجيل الحضور' : 'Attendance System';
  String get attendance => isArabic ? 'تسجيل الحضور' : 'Attendance';
  String get adminPanel => isArabic ? 'لوحة التحكم' : 'Admin Panel';
  String get stats => isArabic ? 'نظرة عامة على الإحصائيات' : 'Overview & Stats';
  String get managePeople => isArabic ? 'إدارة الأشخاص وسجلات الأيام' : 'People & Daily Logs';

  // Date & Day strings
  String get today => isArabic ? 'اليوم' : 'Today';
  String get todayAttendance => isArabic ? 'حضور اليوم' : "Today's Attendance";
  String get markedAt => isArabic ? 'تم التسجيل في' : 'Recorded at';
  String get alreadyMarkedToday => isArabic ? 'تم تسجيل حالة هذا اليوم مسبقاً' : 'Status already recorded for this day';
  String get updateTodayStatus => isArabic ? 'تعديل حالة اليوم' : "Update Status";
  String get attendedToday => isArabic ? 'حاضر اليوم' : 'Attended Today';
  String get absentToday => isArabic ? 'غائب اليوم' : 'Absent Today';
  String get unmarkedToday => isArabic ? 'غير مسجل اليوم' : 'Not Marked Yet';

  // Admin Date Filter & Status
  String get filterByDate => isArabic ? 'تصفية حسب اليوم' : 'Filter by Day';
  String get selectDate => isArabic ? 'اختر التاريخ' : 'Select Date';
  String get filterAll => isArabic ? 'الكل' : 'All';
  String get filterAttended => isArabic ? 'حاضر' : 'Attended';
  String get filterAbsent => isArabic ? 'غائب' : 'Absent';
  String get filterUnmarked => isArabic ? 'غير مسجل' : 'Unmarked';
  String get onDate => isArabic ? 'بتاريخ' : 'on';
  String get noRecordsForDate => isArabic ? 'لا توجد سجلات لهذا اليوم' : 'No records for this date';
  String get changeDate => isArabic ? 'تغيير التاريخ' : 'Change Date';
  String get attendanceOnDate => isArabic ? 'سجل الحضور ليوم' : 'Attendance for';

  // Search & Main Panel (Using "حاضر" / Attendee)
  String get searchHint => isArabic ? 'ابحث بالاسم (عربي/إنجليزي) أو الرقم...' : 'Search name (EN/AR) or ID...';
  String get totalAttendees => isArabic ? 'إجمالي الحاضرين اليوم' : 'Attended Today';
  String get totalPeople => isArabic ? 'إجمالي الأشخاص' : 'Total People';
  String get totalAbsences => isArabic ? 'إجمالي الغياب' : 'Total Absences';
  String get perfectAttendance => isArabic ? 'التزام كامل (0 غياب)' : 'Zero Absences';
  String get avgAbsenceRate => isArabic ? 'معدل الغياب' : 'Avg Absences/Person';
  String get absencesCount => isArabic ? 'مرات الغياب' : 'Absences';
  String get noPeopleFound => isArabic ? 'لا توجد نتائج مطابقة' : 'No matching results found';

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

  // Admin Panel (Using "شخص" / Person)
  String get addPerson => isArabic ? 'إضافة شخص جديد' : 'Add New Person';
  String get editPerson => isArabic ? 'تعديل بيانات الشخص' : 'Edit Person';
  String get deletePerson => isArabic ? 'حذف الشخص' : 'Delete Person';
  String get confirmDelete => isArabic ? 'هل أنت متأكد من رغبتك في حذف هذا الشخص؟ لا يمكن التراجع عن هذا الإجراء.' : 'Are you sure you want to delete this person? This action cannot be undone.';
  String get personNameEn => isArabic ? 'الاسم بالإنجليزية' : 'English Name';
  String get personNameAr => isArabic ? 'الاسم بالعربية' : 'Arabic Name';
  String get personId => isArabic ? 'كود الشخص (ID)' : 'Person ID / Code';
  String get initialAbsences => isArabic ? 'عدد مرات الغياب' : 'Absence Count';
  String get autoGenerateId => isArabic ? 'توليد كود تلقائي' : 'Auto Generate ID';
  String get personAdded => isArabic ? 'تمت إضافة الشخص بنجاح' : 'Person added successfully';
  String get personUpdated => isArabic ? 'تم تحديث بيانات الشخص' : 'Person updated successfully';
  String get personDeleted => isArabic ? 'تم حذف الشخص' : 'Person deleted';
  String get fillRequiredFields => isArabic ? 'يرجى إدخال جميع الحقول المطلوبة' : 'Please fill in all required fields';

  // QR Code
  String get scanQr => isArabic ? 'مسح رمز QR' : 'Scan QR';
  String get viewQr => isArabic ? 'رمز QR' : 'View QR';
  String get qrCodeTitle => isArabic ? 'رمز الاستجابة السريعة (QR)' : 'Person QR Code';
  String get qrInstructions => isArabic ? 'استخدم هذا الرمز للمسح السريع وتسجيل الحضور' : 'Use this code for instant attendance scanning';
  String get personNotFound => isArabic ? 'لم يتم العثور على السجل' : 'Record not found';
  String get attendanceRecorded => isArabic ? 'تم تسجيل الحضور بنجاح' : 'Attendance recorded successfully';

  // Excel & Settings
  String get importExcel => isArabic ? 'استيراد من Excel' : 'Import Excel';
  String get importSuccess => isArabic ? 'تم استيراد البيانات بنجاح' : 'Data imported successfully';
  String get selectFile => isArabic ? 'اختر ملف Excel (.xlsx)' : 'Select Excel File (.xlsx)';
  String get parsingFile => isArabic ? 'جاري معالجة الملف والرفع...' : 'Parsing file and uploading...';
  String get toggleTheme => isArabic ? 'تبديل المظهر' : 'Toggle Theme';
  String get language => isArabic ? 'English' : 'العربية';
}
