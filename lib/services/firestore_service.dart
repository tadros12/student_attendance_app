import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/attendance_log_model.dart';

class AttendanceService {
  final FirebaseFirestore? _firestore;
  final SharedPreferences _prefs;
  final bool _isFirebaseReady;

  static const String _localStudentsKey = 'local_cached_students_data';
  static const String _localLogsKey = 'local_cached_logs_data';

  final StreamController<List<Student>> _localStudentStreamController =
      StreamController<List<Student>>.broadcast();

  AttendanceService({
    FirebaseFirestore? firestore,
    required SharedPreferences prefs,
    bool isFirebaseReady = false,
  })  : _firestore = isFirebaseReady ? (firestore ?? FirebaseFirestore.instance) : null,
        _prefs = prefs,
        _isFirebaseReady = isFirebaseReady {
    if (_isFirebaseReady && _firestore != null) {
      try {
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        debugPrint('Firestore settings notice: $e');
      }
    } else {
      _seedInitialDataIfNeeded();
    }
  }

  void _seedInitialDataIfNeeded() {
    final existing = _prefs.getString(_localStudentsKey);
    if (existing == null || existing.isEmpty) {
      final initialStudents = [
        const Student(id: 'STU-1001', nameEn: 'Ahmed Mansour', nameAr: 'أحمد منصور', totalAbsences: 0),
        const Student(id: 'STU-1002', nameEn: 'Sarah Jenkins', nameAr: 'سارة جنكينز', totalAbsences: 1),
        const Student(id: 'STU-1003', nameEn: 'Youssef Hassan', nameAr: 'يوسف حسن', totalAbsences: 3),
        const Student(id: 'STU-1004', nameEn: 'Mariam Khalil', nameAr: 'مريم خليل', totalAbsences: 0),
        const Student(id: 'STU-1005', nameEn: 'Omar Farooq', nameAr: 'عمر فاروق', totalAbsences: 2),
        const Student(id: 'STU-1006', nameEn: 'Layla Mahmoud', nameAr: 'ليلى محمود', totalAbsences: 0),
      ];
      _saveLocalStudents(initialStudents);
    }
  }

  List<Student> _getLocalStudents() {
    final jsonStr = _prefs.getString(_localStudentsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => Student.fromMap(Map<String, dynamic>.from(item), item['id'] ?? '')).toList();
    } catch (e) {
      debugPrint('Error decoding local students: $e');
      return [];
    }
  }

  Future<void> _saveLocalStudents(List<Student> students) async {
    final list = students.map((s) => s.toMap()).toList();
    await _prefs.setString(_localStudentsKey, jsonEncode(list));
    _localStudentStreamController.add(students);
  }

  /// Real-time stream of all students (Firestore or resilient Local Cache)
  Stream<List<Student>> getStudentsStream() {
    if (_isFirebaseReady && _firestore != null) {
      try {
        return _firestore
            .collection(AppConstants.studentsCollection)
            .snapshots(includeMetadataChanges: true)
            .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            // Fallback to local if remote has not been seeded yet
            final local = _getLocalStudents();
            if (local.isNotEmpty) return local;
          }
          return snapshot.docs
              .map((doc) => Student.fromMap(doc.data(), doc.id))
              .toList();
        }).handleError((error) {
          debugPrint('Firestore stream error, falling back to local: $error');
          return _getLocalStudents();
        });
      } catch (e) {
        debugPrint('Firestore setup error: $e');
      }
    }

    // Local stream with initial value
    Future.microtask(() => _localStudentStreamController.add(_getLocalStudents()));
    return _localStudentStreamController.stream;
  }

  /// Fetch a single student by ID
  Future<Student?> getStudentById(String studentId) async {
    if (_isFirebaseReady && _firestore != null) {
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
    }

    // Fallback to local
    final localList = _getLocalStudents();
    try {
      return localList.firstWhere((s) => s.id == studentId);
    } catch (_) {
      return null;
    }
  }

  /// Records attendance and atomically updates absence count
  Future<void> recordAttendance({
    required String studentId,
    required bool status,
    String? notes,
    required String markedBy,
  }) async {
    // 1. Try Firestore if active
    if (_isFirebaseReady && _firestore != null) {
      try {
        final batch = _firestore.batch();
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

        if (!status) {
          final studentDocRef = _firestore.collection(AppConstants.studentsCollection).doc(studentId);
          batch.update(studentDocRef, {'total_absences': FieldValue.increment(1)});
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore write error: $e');
      }
    }

    // 2. Always persist locally
    final students = _getLocalStudents();
    final index = students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final current = students[index];
      final updated = current.copyWith(
        totalAbsences: !status ? current.totalAbsences + 1 : current.totalAbsences,
      );
      students[index] = updated;
      await _saveLocalStudents(students);
    }

    // Save log locally
    final logsJson = _prefs.getString(_localLogsKey);
    List<dynamic> logs = logsJson != null ? jsonDecode(logsJson) : [];
    logs.add({
      'log_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'student_id': studentId,
      'date': DateTime.now().toIso8601String(),
      'status': status,
      'notes': notes,
      'marked_by': markedBy,
    });
    await _prefs.setString(_localLogsKey, jsonEncode(logs));
  }

  /// Batch upload parsed students from Excel
  Future<int> batchUploadStudents(List<Student> newStudents) async {
    if (_isFirebaseReady && _firestore != null) {
      try {
        int totalUploaded = 0;
        const int chunkSize = 450;

        for (int i = 0; i < newStudents.length; i += chunkSize) {
          final chunk = newStudents.sublist(
            i,
            (i + chunkSize > newStudents.length) ? newStudents.length : i + chunkSize,
          );

          final batch = _firestore.batch();
          for (final student in chunk) {
            final docRef = _firestore.collection(AppConstants.studentsCollection).doc(student.id);
            batch.set(docRef, student.toMap(), SetOptions(merge: true));
          }

          await batch.commit();
          totalUploaded += chunk.length;
        }
      } catch (e) {
        debugPrint('Firestore batch upload error: $e');
      }
    }

    // Merge locally
    final current = _getLocalStudents();
    final Map<String, Student> map = {for (var s in current) s.id: s};
    for (var s in newStudents) {
      map[s.id] = s;
    }
    await _saveLocalStudents(map.values.toList());
    return newStudents.length;
  }
}
