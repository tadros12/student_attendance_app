import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceLog {
  final String logId;
  final String studentId;
  final DateTime date;
  final String dateKey; // Format: "YYYY-MM-DD"
  final bool status; // true = attended, false = absent
  final String? notes;
  final String markedBy;

  const AttendanceLog({
    required this.logId,
    required this.studentId,
    required this.date,
    required this.dateKey,
    required this.status,
    this.notes,
    required this.markedBy,
  });

  static String formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  factory AttendanceLog.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final String dateKey = map['date_key'] as String? ?? formatDateKey(parsedDate);

    return AttendanceLog(
      logId: docId.isNotEmpty ? docId : (map['log_id'] as String? ?? ''),
      studentId: map['student_id'] as String? ?? '',
      date: parsedDate,
      dateKey: dateKey,
      status: map['status'] as bool? ?? true,
      notes: map['notes'] as String?,
      markedBy: map['marked_by'] as String? ?? 'Local Device',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'log_id': logId,
      'student_id': studentId,
      'date': Timestamp.fromDate(date),
      'date_key': dateKey,
      'status': status,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'marked_by': markedBy,
    };
  }
}
