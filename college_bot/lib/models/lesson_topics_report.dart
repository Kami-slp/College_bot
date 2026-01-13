class LessonTopicsReport {
  final List<String> invalidTopics;

  LessonTopicsReport({required this.invalidTopics});

  @override
  String toString() {
    if (invalidTopics.isEmpty) {
      return 'Все темы соответствуют формату "Урок № _. Тема: _"';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Темы, не соответствующие формату:');
    buffer.writeln('');
    
    for (var i = 0; i < invalidTopics.length; i++) {
      buffer.writeln('${i + 1}. ${invalidTopics[i]}');
    }
    
    return buffer.toString();
  }
}
