class CheckedHomeworkReport {
  final List<TeacherHomeworkCheck> teachers;

  CheckedHomeworkReport({required this.teachers});

  @override
  String toString() {
    if (teachers.isEmpty) {
      return 'Преподаватели с низким процентом проверки не найдены';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Преподаватели с процентом проверки ниже 70%:');
    buffer.writeln('');
    
    for (var i = 0; i < teachers.length; i++) {
      final teacher = teachers[i];
      buffer.writeln('${i + 1}. ${teacher.name}');
      buffer.writeln('   Процент проверки: ${teacher.checkPercentage.toStringAsFixed(1)}%');
      buffer.writeln('   Проверено: ${teacher.checked} из ${teacher.total}');
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
}

class TeacherHomeworkCheck {
  final String name;
  final int checked;
  final int total;
  final double checkPercentage;

  TeacherHomeworkCheck({
    required this.name,
    required this.checked,
    required this.total,
    required this.checkPercentage,
  });
}

class SubmittedHomeworkReport {
  final List<StudentHomeworkSubmission> students;

  SubmittedHomeworkReport({required this.students});

  @override
  String toString() {
    if (students.isEmpty) {
      return 'Студенты с низким процентом выполнения не найдены';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Студенты с процентом выполнения ниже 70%:');
    buffer.writeln('');
    
    for (var i = 0; i < students.length; i++) {
      final student = students[i];
      buffer.writeln('${i + 1}. ${student.name}');
      buffer.writeln('   Группа: ${student.group}');
      buffer.writeln('   Процент выполнения: ${student.submissionPercentage.toStringAsFixed(1)}%');
      buffer.writeln('   Сдано: ${student.submitted} из ${student.total}');
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
}

class StudentHomeworkSubmission {
  final String name;
  final String group;
  final int submitted;
  final int total;
  final double submissionPercentage;

  StudentHomeworkSubmission({
    required this.name,
    required this.group,
    required this.submitted,
    required this.total,
    required this.submissionPercentage,
  });
}
