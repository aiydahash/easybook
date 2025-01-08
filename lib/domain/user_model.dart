class AppUser {
  final String id;
  final String name;
  final String matricID;
  final String email;
  final String role;
  final String? course;
  final String? semester;
  final Map<String, dynamic>? additionalInfo;

  AppUser({
    required this.id,
    required this.name,
    required this.matricID,
    required this.email,
    required this.role,
    this.course,
    this.semester,
    this.additionalInfo,
  });

  // Factory constructor to create an AppUser from a Map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['uid'] ?? '',
      name: map['name'] ?? '',
      matricID: map['matricID'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      course: map['course'],
      semester: map['semester'],
      additionalInfo: map['additionalInfo'],
    );
  }

  // Convert AppUser to a Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'matricID': matricID,
      'email': email,
      'role': role,
      'course': course,
      'semester': semester,
      'additionalInfo': additionalInfo,
    };
  }

  // Method to create a copy of AppUser with updated fields
  AppUser copyWith({
    String? name,
    String? course,
    String? semester,
    Map<String, dynamic>? additionalInfo,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      matricID: matricID,
      email: email,
      role: role,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
