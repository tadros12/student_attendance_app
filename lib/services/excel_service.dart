import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/student_model.dart';

class ExcelService {
  /// Open local file picker for .xlsx files
  Future<File?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Parse bytes of the Excel workbook into a List<Student>
  Future<List<Student>> parseStudentsFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final List<Student> parsedStudents = [];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows <= 1) continue;

      int idCol = 0;
      int nameEnCol = 1;
      int nameArCol = 2;
      int absencesCol = 3;

      bool hasHeader = false;
      final firstRow = sheet.rows.first;

      // Inspect header row if present
      for (int i = 0; i < firstRow.length; i++) {
        final cellVal = firstRow[i]?.value?.toString().toLowerCase().trim() ?? '';
        if (cellVal.contains('id') || cellVal.contains('رقم') || cellVal.contains('كود')) {
          idCol = i;
          hasHeader = true;
        } else if (cellVal.contains('en') || cellVal.contains('english')) {
          nameEnCol = i;
          hasHeader = true;
        } else if (cellVal.contains('ar') || cellVal.contains('عربي') || cellVal.contains('arabic')) {
          nameArCol = i;
          hasHeader = true;
        } else if (cellVal.contains('absence') || cellVal.contains('غياب')) {
          absencesCol = i;
          hasHeader = true;
        }
      }

      final startRow = hasHeader ? 1 : 0;

      for (int rowIndex = startRow; rowIndex < sheet.rows.length; rowIndex++) {
        final row = sheet.rows[rowIndex];
        if (row.isEmpty) continue;

        final id = row.length > idCol ? row[idCol]?.value?.toString().trim() ?? '' : '';
        if (id.isEmpty) continue;

        final nameEn = row.length > nameEnCol ? row[nameEnCol]?.value?.toString().trim() ?? '' : '';
        final nameAr = row.length > nameArCol ? row[nameArCol]?.value?.toString().trim() ?? '' : '';
        
        int absences = 0;
        if (row.length > absencesCol && row[absencesCol]?.value != null) {
          absences = int.tryParse(row[absencesCol]!.value.toString().trim()) ?? 0;
        }

        parsedStudents.add(Student(
          id: id,
          nameEn: nameEn.isNotEmpty ? nameEn : 'Student $id',
          nameAr: nameAr.isNotEmpty ? nameAr : nameEn,
          totalAbsences: absences,
        ));
      }
    }

    return parsedStudents;
  }
}
