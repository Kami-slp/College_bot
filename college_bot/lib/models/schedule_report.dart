class ScheduleReport {
  final Map<String, int> disciplineCounts;

  ScheduleReport({required this.disciplineCounts});

  @override
  String toString() {
    if (disciplineCounts.isEmpty) {
      return 'Данные не найдены';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Количество пар по дисциплинам:');
    buffer.writeln('');
    
    disciplineCounts.forEach((discipline, count) {
      buffer.writeln('$discipline: $count пар');
    });
    
    return buffer.toString();
  }
}
