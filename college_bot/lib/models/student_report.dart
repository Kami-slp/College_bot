class StudentReport {
  final List<StudentInfo> students;

  StudentReport({required this.students});

  @override
  String toString() {
    if (students.isEmpty) {
      return 'Студенты с проблемными оценками не найдены';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Студенты с проблемными оценками:');
    buffer.writeln('');
    
    for (var i = 0; i < students.length; i++) {
      final student = students[i];
      buffer.writeln('${i + 1}. ${student.name}');
      buffer.writeln('   Группа: ${student.group}');
      buffer.writeln('   Средняя оценка за ДЗ: ${student.homeworkAverage}');
      buffer.writeln('   Оценка за классную работу: ${student.classroomGrade}');
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
}

class StudentInfo {
  final String name;
  final String group;
  final double homeworkAverage;
  final double classroomGrade;

  StudentInfo({
    required this.name,
    required this.group,
    required this.homeworkAverage,
    required this.classroomGrade,
  });
}
