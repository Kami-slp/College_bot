class AttendanceReport {
  final List<TeacherAttendance> teachers;

  AttendanceReport({required this.teachers});

  @override
  String toString() {
    if (teachers.isEmpty) {
      return 'Преподаватели с низкой посещаемостью не найдены';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Преподаватели с посещаемостью ниже 40%:');
    buffer.writeln('');
    
    for (var i = 0; i < teachers.length; i++) {
      final teacher = teachers[i];
      buffer.writeln('${i + 1}. ${teacher.name}');
      buffer.writeln('   Посещаемость: ${teacher.attendancePercentage.toStringAsFixed(1)}%');
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
}

class TeacherAttendance {
  final String name;
  final double attendancePercentage;

  TeacherAttendance({
    required this.name,
    required this.attendancePercentage,
  });
}
