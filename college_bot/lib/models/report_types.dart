enum ReportType {
  schedule,
  lessonTopics,
  students,
  attendance,
  checkedHomework,
  submittedHomework,
}

extension ReportTypeExtension on ReportType {
  String get title {
    switch (this) {
      case ReportType.schedule:
        return 'Отчет по расписанию';
      case ReportType.lessonTopics:
        return 'Отчет по темам занятия';
      case ReportType.students:
        return 'Отчет по студентам';
      case ReportType.attendance:
        return 'Отчет по посещаемости';
      case ReportType.checkedHomework:
        return 'Отчет по проверенным ДЗ';
      case ReportType.submittedHomework:
        return 'Отчет по сданным ДЗ';
    }
  }

  String get description {
    switch (this) {
      case ReportType.schedule:
        return 'Показывает количество пар по каждой дисциплине';
      case ReportType.lessonTopics:
        return 'Проверяет формат тем занятий';
      case ReportType.students:
        return 'Студенты с проблемными оценками';
      case ReportType.attendance:
        return 'Преподаватели с низкой посещаемостью';
      case ReportType.checkedHomework:
        return 'Преподаватели с низким % проверки ДЗ';
      case ReportType.submittedHomework:
        return 'Студенты с низким % выполнения ДЗ';
    }
  }
}
