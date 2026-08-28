class Student {
  final String id;
  final String nameEn;
  final String nameAr;
  final int totalAbsences;
  final String? notes;
  final String? lastAttendanceDate;
  final bool? todayStatus;

  const Student({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.totalAbsences = 0,
    this.notes,
    this.lastAttendanceDate,
    this.todayStatus,
  });

  factory Student.fromMap(Map<String, dynamic> map, String documentId) {
    return Student(
      id: documentId.isNotEmpty ? documentId : (map['id'] as String? ?? ''),
      nameEn: map['name_en'] as String? ?? '',
      nameAr: map['name_ar'] as String? ?? '',
      totalAbsences: (map['total_absences'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
      lastAttendanceDate: map['last_attendance_date'] as String?,
      todayStatus: map['today_status'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_ar': nameAr,
      'total_absences': totalAbsences,
      if (notes != null) 'notes': notes,
      if (lastAttendanceDate != null) 'last_attendance_date': lastAttendanceDate,
      if (todayStatus != null) 'today_status': todayStatus,
    };
  }

  Student copyWith({
    String? id,
    String? nameEn,
    String? nameAr,
    int? totalAbsences,
    String? notes,
    String? lastAttendanceDate,
    bool? todayStatus,
  }) {
    return Student(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      totalAbsences: totalAbsences ?? this.totalAbsences,
      notes: notes ?? this.notes,
      lastAttendanceDate: lastAttendanceDate ?? this.lastAttendanceDate,
      todayStatus: todayStatus ?? this.todayStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
