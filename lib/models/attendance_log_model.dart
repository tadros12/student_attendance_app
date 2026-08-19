import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceLog {
  final String logId;
  final String studentId;
  final DateTime date;
  final bool status; // true = attended, false = absent
  final String? notes;
  final String markedBy;

  const AttendanceLog({
    required this.logId,
    required this.studentId,
    required this.date,
    required this.status,
    this.notes,
    required this.markedBy,
  });

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

    return AttendanceLog(
      logId: docId.isNotEmpty ? docId : (map['log_id'] as String? ?? ''),
      studentId: map['student_id'] as String? ?? '',
      date: parsedDate,
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
      'status': status,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'marked_by': markedBy,
    };
  }
}
