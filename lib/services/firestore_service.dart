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
  final Map<String, StreamController<Map<String, AttendanceLog>>> _dateControllers = {};

  AttendanceService({
    FirebaseFirestore? firestore,
    required SharedPreferences prefs,
    bool isFirebaseReady = false,
  })  : _firestore = isFirebaseReady ? (firestore ?? FirebaseFirestore.instance) : null,
        _prefs = prefs,
        _isFirebaseReady = isFirebaseReady {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        fs.settings = const Settings(
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
        const Student(id: 'STU-1001', nameEn: 'Ahmed Mansour', nameAr: 'أحمد منصور', totalAbsences: 0, notes: 'Honor roll member'),
        const Student(id: 'STU-1002', nameEn: 'Sarah Jenkins', nameAr: 'سارة جنكينز', totalAbsences: 1, notes: 'Excused on Monday'),
        const Student(id: 'STU-1003', nameEn: 'Youssef Hassan', nameAr: 'يوسف حسن', totalAbsences: 3, notes: 'Follow up required'),
        const Student(id: 'STU-1004', nameEn: 'Mariam Khalil', nameAr: 'مريم خليل', totalAbsences: 0, notes: 'Team leader'),
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

  List<AttendanceLog> _getLocalLogs() {
    final jsonStr = _prefs.getString(_localLogsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => AttendanceLog.fromMap(Map<String, dynamic>.from(item), item['log_id'] ?? '')).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveLocalLogs(List<AttendanceLog> logs) async {
    final list = logs.map((l) => l.toMap()).toList();
    await _prefs.setString(_localLogsKey, jsonEncode(list));
    // Notify all active date stream listeners
    for (final entry in _dateControllers.entries) {
      final dateKey = entry.key;
      final controller = entry.value;
      final map = <String, AttendanceLog>{};
      for (final log in logs) {
        if (log.dateKey == dateKey) map[log.studentId] = log;
      }
      controller.add(map);
    }
  }

  /// Real-time stream of all students
  Stream<List<Student>> getStudentsStream() {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        return fs
            .collection(AppConstants.studentsCollection)
            .snapshots(includeMetadataChanges: true)
            .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            final local = _getLocalStudents();
            if (local.isNotEmpty) return local;
          }
          return snapshot.docs
              .map((doc) => Student.fromMap(doc.data(), doc.id))
              .toList();
        }).handleError((error) {
          debugPrint('Firestore stream error: $error');
          return _getLocalStudents();
        });
      } catch (e) {
        debugPrint('Firestore setup error: $e');
      }
    }

    Future.microtask(() => _localStudentStreamController.add(_getLocalStudents()));
    return _localStudentStreamController.stream;
  }

  /// Real-time stream of attendance logs for ANY date (studentId -> AttendanceLog)
  Stream<Map<String, AttendanceLog>> getLogsForDateStream(String dateKey) {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        return fs
            .collection(AppConstants.attendanceLogsCollection)
            .where('date_key', isEqualTo: dateKey)
            .snapshots(includeMetadataChanges: true)
            .map((snapshot) {
          final map = <String, AttendanceLog>{};
          for (final doc in snapshot.docs) {
            final log = AttendanceLog.fromMap(doc.data(), doc.id);
            map[log.studentId] = log;
          }
          return map;
        }).handleError((error) {
          debugPrint('Firestore date logs stream error: $error');
          final logs = _getLocalLogs();
          final localMap = <String, AttendanceLog>{};
          for (final log in logs) {
            if (log.dateKey == dateKey) localMap[log.studentId] = log;
          }
          return localMap;
        });
      } catch (e) {
        debugPrint('Firestore date logs error: $e');
      }
    }

    // Local stream controller
    if (!_dateControllers.containsKey(dateKey)) {
      _dateControllers[dateKey] = StreamController<Map<String, AttendanceLog>>.broadcast();
    }
    final controller = _dateControllers[dateKey]!;

    Future.microtask(() {
      final logs = _getLocalLogs();
      final localMap = <String, AttendanceLog>{};
      for (final log in logs) {
        if (log.dateKey == dateKey) localMap[log.studentId] = log;
      }
      controller.add(localMap);
    });

    return controller.stream;
  }

  /// Real-time stream of today's attendance logs
  Stream<Map<String, AttendanceLog>> getTodayAttendanceMapStream() {
    final todayKey = AttendanceLog.formatDateKey(DateTime.now());
    return getLogsForDateStream(todayKey);
  }

  /// Fetch a single student by ID
  Future<Student?> getStudentById(String studentId) async {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        final doc = await fs
            .collection(AppConstants.studentsCollection)
            .doc(studentId)
            .get(const GetOptions(source: Source.serverAndCache));
        if (doc.exists && doc.data() != null) {
          return Student.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {
        try {
          final cacheDoc = await fs
              .collection(AppConstants.studentsCollection)
              .doc(studentId)
              .get(const GetOptions(source: Source.cache));
          if (cacheDoc.exists && cacheDoc.data() != null) {
            return Student.fromMap(cacheDoc.data()!, cacheDoc.id);
          }
        } catch (_) {}
      }
    }

    final localList = _getLocalStudents();
    try {
      return localList.firstWhere((s) => s.id == studentId);
    } catch (_) {
      return null;
    }
  }

  /// Get attendance log for a student on a specific date
  Future<AttendanceLog?> getLogForStudentOnDate(String studentId, String dateKey) async {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        final query = await fs
            .collection(AppConstants.attendanceLogsCollection)
            .where('student_id', isEqualTo: studentId)
            .where('date_key', isEqualTo: dateKey)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          return AttendanceLog.fromMap(query.docs.first.data(), query.docs.first.id);
        }
      } catch (_) {}
    }

    final localLogs = _getLocalLogs();
    try {
      return localLogs.firstWhere((l) => l.studentId == studentId && l.dateKey == dateKey);
    } catch (_) {
      return null;
    }
  }

  Future<AttendanceLog?> getTodayLogForStudent(String studentId) {
    return getLogForStudentOnDate(studentId, AttendanceLog.formatDateKey(DateTime.now()));
  }

  /// Add a new person
  Future<void> addStudent(Student student) async {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        await fs
            .collection(AppConstants.studentsCollection)
            .doc(student.id)
            .set(student.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore add person error: $e');
      }
    }

    final students = _getLocalStudents();
    students.removeWhere((s) => s.id == student.id);
    students.insert(0, student);
    await _saveLocalStudents(students);
  }

  /// Update an existing person
  Future<void> updateStudent(Student student) async {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        await fs
            .collection(AppConstants.studentsCollection)
            .doc(student.id)
            .set(student.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore update person error: $e');
      }
    }

    final students = _getLocalStudents();
    final index = students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      students[index] = student;
    } else {
      students.add(student);
    }
    await _saveLocalStudents(students);
  }

  /// Delete a person
  Future<void> deleteStudent(String studentId) async {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        await fs
            .collection(AppConstants.studentsCollection)
            .doc(studentId)
            .delete();
      } catch (e) {
        debugPrint('Firestore delete person error: $e');
      }
    }

    final students = _getLocalStudents();
    students.removeWhere((s) => s.id == studentId);
    await _saveLocalStudents(students);
  }

  /// Update person notes
  Future<void> updateStudentNotes(String studentId, String notes) async {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        await fs
            .collection(AppConstants.studentsCollection)
            .doc(studentId)
            .update({'notes': notes});
      } catch (e) {
        debugPrint('Firestore update notes error: $e');
      }
    }

    final students = _getLocalStudents();
    final index = students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      students[index] = students[index].copyWith(notes: notes);
      await _saveLocalStudents(students);
    }
  }

  /// Records attendance for a specific date (defaults to now) with Same-Day Duplicate Prevention
  Future<void> recordAttendance({
    required String studentId,
    required bool status,
    String? notes,
    required String markedBy,
    DateTime? date,
  }) async {
    final recordDate = date ?? DateTime.now();
    final dateKey = AttendanceLog.formatDateKey(recordDate);
    final logDocId = '${studentId}_$dateKey';

    final existingLog = await getLogForStudentOnDate(studentId, dateKey);
    int absenceDelta = 0;

    if (existingLog == null) {
      if (!status) absenceDelta = 1;
    } else {
      if (existingLog.status == false && status == true) {
        absenceDelta = -1;
      } else if (existingLog.status == true && status == false) {
        absenceDelta = 1;
      }
    }

    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        final batch = fs.batch();
        final logDocRef = fs.collection(AppConstants.attendanceLogsCollection).doc(logDocId);
        final log = AttendanceLog(
          logId: logDocId,
          studentId: studentId,
          date: recordDate,
          dateKey: dateKey,
          status: status,
          notes: notes,
          markedBy: markedBy,
        );
        batch.set(logDocRef, log.toMap(), SetOptions(merge: true));

        final studentDocRef = fs.collection(AppConstants.studentsCollection).doc(studentId);
        final Map<String, dynamic> studentUpdates = {
          'last_attendance_date': dateKey,
          'today_status': status,
        };
        if (absenceDelta != 0) {
          studentUpdates['total_absences'] = FieldValue.increment(absenceDelta);
        }
        if (notes != null && notes.isNotEmpty) {
          studentUpdates['notes'] = notes;
        }
        batch.update(studentDocRef, studentUpdates);

        await batch.commit();
      } catch (e) {
        debugPrint('Firestore write error: $e');
      }
    }

    // Local storage update
    final students = _getLocalStudents();
    final index = students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final current = students[index];
      final newAbsences = (current.totalAbsences + absenceDelta).clamp(0, 9999);
      final updated = current.copyWith(
        totalAbsences: newAbsences,
        notes: (notes != null && notes.isNotEmpty) ? notes : current.notes,
        lastAttendanceDate: dateKey,
        todayStatus: status,
      );
      students[index] = updated;
      await _saveLocalStudents(students);
    }

    // Update local logs
    final logs = _getLocalLogs();
    final logIndex = logs.indexWhere((l) => l.studentId == studentId && l.dateKey == dateKey);
    final newLog = AttendanceLog(
      logId: logDocId,
      studentId: studentId,
      date: recordDate,
      dateKey: dateKey,
      status: status,
      notes: notes,
      markedBy: markedBy,
    );

    if (logIndex != -1) {
      logs[logIndex] = newLog;
    } else {
      logs.add(newLog);
    }
    await _saveLocalLogs(logs);
  }

  /// Batch upload parsed students from Excel
  Future<int> batchUploadStudents(List<Student> newStudents) async {
    final fs = _firestore;
    if (_isFirebaseReady && fs != null) {
      try {
        const int chunkSize = 450;
        for (int i = 0; i < newStudents.length; i += chunkSize) {
          final chunk = newStudents.sublist(
            i,
            (i + chunkSize > newStudents.length) ? newStudents.length : i + chunkSize,
          );

          final batch = fs.batch();
          for (final student in chunk) {
            final docRef = fs.collection(AppConstants.studentsCollection).doc(student.id);
            batch.set(docRef, student.toMap(), SetOptions(merge: true));
          }

          await batch.commit();
        }
      } catch (e) {
        debugPrint('Firestore batch upload error: $e');
      }
    }

    final current = _getLocalStudents();
    final Map<String, Student> map = {for (var s in current) s.id: s};
    for (var s in newStudents) {
      map[s.id] = s;
    }
    await _saveLocalStudents(map.values.toList());
    return newStudents.length;
  }
}
