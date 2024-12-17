class AppUser {
  final String id;
  final String name;
  final String matricID;
  final String email;
  final String role;
  final String? course;
  final String? semester;

  AppUser({
    required this.id,
    required this.name,
    required this.matricID,
    required this.email,
    required this.role,
    this.course,
    this.semester,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'] ?? data['uid'] ?? '',
      name: data['name'] ?? '',
      matricID: data['matricID'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      course: data['course'],
      semester: data['semester'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'matricID': matricID,
      'email': email,
      'role': role,
      'course': course,
      'semester': semester,
    };
  }

  AppUser copyWith({
    String? name,
    String? matricID,
    String? course,
    String? semester,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      matricID: matricID ?? this.matricID,
      email: email,
      role: role,
      course: course ?? this.course,
      semester: semester ?? this.semester,
    );
  }
}