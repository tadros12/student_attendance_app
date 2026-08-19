import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/attendance_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _initOfflineSettings();
  }

  void _initOfflineSettings() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      // Settings can only be set before any other Firestore operations
    }
  }

  /// Real-time stream of all students from local cache & remote Firestore
  Stream<List<Student>> getStudentsStream() {
    return _firestore
        .collection(AppConstants.studentsCollection)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Student.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Fetch a single student record by ID (from cache first if offline)
  Future<Student?> getStudentById(String studentId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.studentsCollection)
          .doc(studentId)
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        return Student.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {
      try {
        final cacheDoc = await _firestore
            .collection(AppConstants.studentsCollection)
            .doc(studentId)
            .get(const GetOptions(source: Source.cache));
        if (cacheDoc.exists && cacheDoc.data() != null) {
          return Student.fromMap(cacheDoc.data()!, cacheDoc.id);
        }
      } catch (_) {}
    }
    return null;
  }

  /// Records attendance and atomically increments absences if student is absent
  Future<void> recordAttendance({
    required String studentId,
    required bool status,
    String? notes,
    required String markedBy,
  }) async {
    final batch = _firestore.batch();

    // 1. Create Attendance Log Doc
    final logDocRef = _firestore.collection(AppConstants.attendanceLogsCollection).doc();
    final log = AttendanceLog(
      logId: logDocRef.id,
      studentId: studentId,
      date: DateTime.now(),
      status: status,
      notes: notes,
      markedBy: markedBy,
    );
    batch.set(logDocRef, log.toMap());

    // 2. If absent, increment total_absences on Student document
    if (!status) {
      final studentDocRef = _firestore.collection(AppConstants.studentsCollection).doc(studentId);
      batch.update(studentDocRef, {
        'total_absences': FieldValue.increment(1),
      });
    }

    // Commits immediately to local SQLite cache, then queues for sync
    await batch.commit();
  }

  /// Batch upload parsed students from Excel (handles >500 items via chunking)
  Future<int> batchUploadStudents(List<Student> students) async {
    int totalUploaded = 0;
    const int chunkSize = 450; // Firestore 500 limit safety buffer

    for (int i = 0; i < students.length; i += chunkSize) {
      final chunk = students.sublist(
        i,
        (i + chunkSize > students.length) ? students.length : i + chunkSize,
      );

      final batch = _firestore.batch();
      for (final student in chunk) {
        final docRef = _firestore.collection(AppConstants.studentsCollection).doc(student.id);
        batch.set(docRef, student.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      totalUploaded += chunk.length;
    }
    return totalUploaded;
  }
}
