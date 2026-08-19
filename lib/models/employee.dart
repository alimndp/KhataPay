class Employee {
  final String id;
  final String? profileId;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? designation;
  final String? department;
  final double baseSalary;
  final DateTime? joiningDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Employee({
    required this.id,
    this.profileId,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.designation,
    this.department,
    required this.baseSalary,
    this.joiningDate,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      profileId: json['profile_id'] as String?,
      employeeCode: json['employee_code'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      designation: json['designation'] as String?,
      department: json['department'] as String?,
      baseSalary: (json['base_salary'] as num?)?.toDouble() ?? 0,
      joiningDate: json['joining_date'] != null
          ? DateTime.parse(json['joining_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'employee_code': employeeCode,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'designation': designation,
      'department': department,
      'base_salary': baseSalary,
      'joining_date': joiningDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}