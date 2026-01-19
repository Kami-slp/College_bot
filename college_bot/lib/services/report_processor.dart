import '../models/report_types.dart';
import '../models/schedule_report.dart';
import '../models/lesson_topics_report.dart';
import '../models/student_report.dart' show StudentReport, StudentInfo;
import '../models/attendance_report.dart' show AttendanceReport, TeacherAttendance;
import '../models/homework_report.dart' show CheckedHomeworkReport, TeacherHomeworkCheck, SubmittedHomeworkReport, StudentHomeworkSubmission;
import 'excel_parser.dart';

class ReportProcessor {
  final ExcelParser _parser = ExcelParser();

  Future<dynamic> processReport(ReportType type, String filePath) async {
    final excel = await _parser.loadExcelFile(filePath);
    if (excel == null) {
      throw Exception('Не удалось загрузить Excel файл');
    }

    final data = _parser.parseExcelToMapList(excel);
    if (data.isEmpty) {
      throw Exception('Файл пуст или не содержит данных');
    }

    switch (type) {
      case ReportType.schedule:
        return _processScheduleReport(data);
      case ReportType.lessonTopics:
        return _processLessonTopicsReport(data);
      case ReportType.students:
        return _processStudentsReport(data);
      case ReportType.attendance:
        return _processAttendanceReport(data);
      case ReportType.checkedHomework:
        return _processCheckedHomeworkReport(data);
      case ReportType.submittedHomework:
        return _processSubmittedHomeworkReport(data);
    }
  }

  ScheduleReport _processScheduleReport(List<Map<String, dynamic>> data) {
    final disciplineCounts = <String, int>{};

    for (var row in data) {
      String? disciplineName;
      
      final possibleNameColumns = [
        'ФИО преподавателя',
        'ФИО',
        'FIO',
        'Преподаватель',
        'Дисциплина',
        'Discipline',
        'Форма обучения',
      ];
      
      for (var col in possibleNameColumns) {
        final name = _parser.getStringValue(row[col]);
        if (name != null && name.isNotEmpty) {
          disciplineName = name;
          break;
        }
      }
      
      if (disciplineName == null || disciplineName.isEmpty) {
        for (var entry in row.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value != null) {
            final strValue = value.toString().trim();
            if (strValue.isNotEmpty && 
                !_isNumeric(strValue) && 
                !_isDate(strValue) && 
                !_isServiceColumn(key) &&
                strValue.length > 2) {
              disciplineName = strValue;
              break;
            }
          }
        }
      }
      
      if (disciplineName == null || disciplineName.isEmpty) continue;
      
      int totalPairs = 0;
      for (var entry in row.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;
        
        if (key.contains('кол-во пар') || 
            key.contains('pairs') || 
            key.contains('количество пар') ||
            (key.contains('пар') && 
             !key.contains('выдано') && 
             !key.contains('получено') &&
             !key.contains('проверено') &&
             !key.contains('план'))) {
          final pairs = _parser.getIntValue(value) ?? 0;
          totalPairs += pairs;
        }
      }
      
      if (totalPairs > 0) {
        disciplineCounts[disciplineName] = totalPairs;
      } else if (disciplineName.isNotEmpty) {
        disciplineCounts[disciplineName] = 0;
      }
    }

    return ScheduleReport(disciplineCounts: disciplineCounts);
  }

  LessonTopicsReport _processLessonTopicsReport(List<Map<String, dynamic>> data) {
    final invalidTopics = <String>[];
    final pattern = RegExp(r'Урок\s*№\s*\d+\.\s*Тема:\s*.+', caseSensitive: false);

    for (var row in data) {
      for (var value in row.values) {
        if (value != null) {
          final strValue = value.toString().trim();
          if (strValue.isNotEmpty && !_isNumeric(strValue) && !_isDate(strValue)) {
            if (strValue.toLowerCase().contains('урок') || 
                strValue.toLowerCase().contains('тема')) {
              if (!pattern.hasMatch(strValue)) {
                invalidTopics.add(strValue);
              }
            }
          }
        }
      }
    }

    return LessonTopicsReport(invalidTopics: invalidTopics);
  }

  StudentReport _processStudentsReport(List<Map<String, dynamic>> data) {
    final students = <StudentInfo>[];

    for (var row in data) {
      final name = _parser.getStringValue(row['FIO']) ?? 
                   _parser.getStringValue(row['ФИО']) ?? 
                   _parser.getStringValue(row['Имя']) ?? '';
      
      if (name.isEmpty) continue;

      final group = _parser.getStringValue(row['Группа']) ?? 
                    _parser.getStringValue(row['Group']) ?? '';

      final homeworkAvg = _parser.getDoubleValue(row['Homework']) ?? 
                         _parser.getDoubleValue(row['Домашняя работа']) ??
                         _parser.getDoubleValue(row['Average score']) ??
                         0.0;

      final classroomGrade = _parser.getDoubleValue(row['Classroom']) ?? 
                            _parser.getDoubleValue(row['Классная работа']) ??
                            0.0;

      if (homeworkAvg == 1.0 && classroomGrade < 3.0) {
        students.add(StudentInfo(
          name: name,
          group: group,
          homeworkAverage: homeworkAvg,
          classroomGrade: classroomGrade,
        ));
      }
    }

    return StudentReport(students: students);
  }

  AttendanceReport _processAttendanceReport(List<Map<String, dynamic>> data) {
    final teachers = <TeacherAttendance>[];

    for (var row in data) {
      final name = _parser.getStringValue(row['FIO']) ?? 
                   _parser.getStringValue(row['ФИО']) ?? 
                   _parser.getStringValue(row['ФИО преподавателя']) ??
                   _parser.getStringValue(row['Преподаватель']) ?? '';
      
      if (name.isEmpty) continue;

      double? attendance;
      
      final possibleColumns = [
        'Percentage of Classroom Grades per month',
        'Процент посещаемости',
        'Посещаемость',
        'Attendance',
        '% посещаемости',
        '% of passed tests for the entire period per month',
      ];

      for (var col in possibleColumns) {
        attendance = _parser.getDoubleValue(row[col]);
        if (attendance != null) break;
      }

      if (attendance == null) {
        for (var entry in row.entries) {
          final key = entry.key.toLowerCase();
          if (key.contains('посещаемость') || 
              key.contains('attendance') ||
              (key.contains('percentage') && key.contains('classroom'))) {
            attendance = _parser.getDoubleValue(entry.value);
            if (attendance != null) break;
          }
        }
      }

      if (attendance == null) {
        final attended = _parser.getIntValue(row['Посещено']) ?? 
                        _parser.getIntValue(row['Attended']) ?? 0;
        final total = _parser.getIntValue(row['Всего']) ?? 
                     _parser.getIntValue(row['Total']) ?? 
                     _parser.getIntValue(row['pairs in total']) ?? 0;
        
        if (total > 0) {
          attendance = (attended / total) * 100;
        }
      }

      if (attendance != null && attendance < 40.0) {
        teachers.add(TeacherAttendance(
          name: name,
          attendancePercentage: attendance,
        ));
      }
    }

    return AttendanceReport(teachers: teachers);
  }

  CheckedHomeworkReport _processCheckedHomeworkReport(List<Map<String, dynamic>> data) {
    final teachers = <TeacherHomeworkCheck>[];

    for (var row in data) {
      final name = _parser.getStringValue(row['FIO']) ?? 
                   _parser.getStringValue(row['ФИО']) ?? 
                   _parser.getStringValue(row['ФИО преподавателя']) ??
                   _parser.getStringValue(row['Преподаватель']) ?? '';
      
      if (name.isEmpty) continue;

      int checked = 0;
      int total = 0;
      
      checked = _parser.getIntValue(row['Проверено']) ?? 
                _parser.getIntValue(row['Number of homework to be checked']) ?? 
                _parser.getIntValue(row['Number of homework to be checked per month']) ??
                0;
      
      total = _parser.getIntValue(row['Выдано']) ?? 
              _parser.getIntValue(row['Всего ДЗ']) ?? 
              _parser.getIntValue(row['Total homework']) ?? 0;

      if (checked == 0 || total == 0) {
        for (var entry in row.entries) {
          final key = entry.key.toLowerCase();
          final value = entry.value;
          
          if (key.contains('проверено') && !key.contains('процент')) {
            final val = _parser.getIntValue(value);
            if (val != null && val > checked) checked = val;
          } else if (key.contains('выдано') || 
                     (key.contains('всего') && key.contains('дз')) ||
                     (key.contains('total') && key.contains('homework'))) {
            final val = _parser.getIntValue(value);
            if (val != null && val > total) total = val;
          }
        }
      }
      
      if (total == 0) {
        for (var entry in row.entries) {
          final key = entry.key.toLowerCase();
          final value = entry.value;
          if (key.contains('выдано')) {
            final val = _parser.getIntValue(value) ?? 0;
            total += val;
          }
        }
      }
      
      if (checked == 0) {
        for (var entry in row.entries) {
          final key = entry.key.toLowerCase();
          final value = entry.value;
          if (key.contains('проверено') && !key.contains('процент')) {
            final val = _parser.getIntValue(value) ?? 0;
            checked += val;
          }
        }
      }

      double? checkPercentage;
      if (total > 0) {
        checkPercentage = (checked / total) * 100;
      } else {
        checkPercentage = _parser.getDoubleValue(
          row['% of passed tests for the entire period per month']
        ) ?? _parser.getDoubleValue(row['Процент проверки']) ?? 
           _parser.getDoubleValue(row['% проверки']);
      }

      if (checkPercentage != null && checkPercentage < 70.0) {
        teachers.add(TeacherHomeworkCheck(
          name: name,
          checked: checked,
          total: total,
          checkPercentage: checkPercentage,
        ));
      }
    }

    return CheckedHomeworkReport(teachers: teachers);
  }

  SubmittedHomeworkReport _processSubmittedHomeworkReport(List<Map<String, dynamic>> data) {
    final students = <StudentHomeworkSubmission>[];

    for (var row in data) {
      final name = _parser.getStringValue(row['FIO']) ?? 
                   _parser.getStringValue(row['ФИО']) ?? 
                   _parser.getStringValue(row['Имя']) ?? '';
      
      if (name.isEmpty) continue;

      final group = _parser.getStringValue(row['Группа']) ?? 
                    _parser.getStringValue(row['Group']) ?? '';

      double? percentageValue = _parser.getDoubleValue(row['Percentage Homework']);

      if (percentageValue != null && percentageValue < 70.0) {
        int submitted = _parser.getIntValue(row['Получено']) ?? 
                       _parser.getIntValue(row['Сдано ДЗ']) ?? 
                       _parser.getIntValue(row['Submitted']) ?? 0;
        int total = _parser.getIntValue(row['Выдано']) ?? 
                   _parser.getIntValue(row['Всего ДЗ']) ?? 
                   _parser.getIntValue(row['Total']) ?? 0;

        if (submitted == 0 || total == 0) {
          for (var entry in row.entries) {
            final key = entry.key.toLowerCase();
            if (key.contains('получено') || 
                (key.contains('сдано') && key.contains('дз')) ||
                (key.contains('submitted'))) {
              submitted = _parser.getIntValue(entry.value) ?? submitted;
            } else if (key.contains('выдано') || 
                       (key.contains('всего') && key.contains('дз')) ||
                       (key.contains('total') && key.contains('homework'))) {
              total = _parser.getIntValue(entry.value) ?? total;
            }
          }
        }

        students.add(StudentHomeworkSubmission(
          name: name,
          group: group,
          submitted: submitted,
          total: total,
          submissionPercentage: percentageValue,
        ));
      }
    }

    return SubmittedHomeworkReport(students: students);
  }

  bool _isNumeric(String str) {
    return double.tryParse(str.replaceAll(',', '.')) != null;
  }

  bool _isDate(String str) {
    return str.contains('-') && str.length > 8;
  }

  bool _isServiceColumn(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey.contains('fio') ||
           lowerKey.contains('фио') ||
           lowerKey.contains('поток') ||
           lowerKey.contains('stream') ||
           lowerKey.contains('группа') ||
           lowerKey.contains('group') ||
           lowerKey.contains('survey') ||
           lowerKey.contains('фото') ||
           lowerKey.contains('photo') ||
           lowerKey.contains('визит') ||
           lowerKey.contains('visit') ||
           lowerKey.contains('рейтинг') ||
           lowerKey.contains('rating') ||
           lowerKey.contains('топгемы') ||
           lowerKey.contains('топкоины') ||
           lowerKey.contains('top') ||
           lowerKey.contains('монеты') ||
           lowerKey.contains('coins') ||
           lowerKey.contains('debt') ||
           lowerKey.contains('долг') ||
           lowerKey.contains('probability') ||
           lowerKey.contains('вероятность') ||
           lowerKey.contains('месяц') ||
           lowerKey.contains('неделя') ||
           lowerKey.contains('день') ||
           lowerKey.contains('форма обучения');
  }
}
