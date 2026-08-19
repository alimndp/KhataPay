class Attendance {
  final String id;
  final String employeeId;
  final DateTime attendanceDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final String? notes;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.status = 'present',
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      attendanceDate: DateTime.parse(json['attendance_date'] as String),
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'] as String).toLocal()
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'] as String).toLocal()
          : null,
      status: json['status'] as String? ?? 'present',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'attendance_date': attendanceDate.toIso8601String().substring(0, 10),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  bool get isCheckedOut => checkOutTime != null;
}