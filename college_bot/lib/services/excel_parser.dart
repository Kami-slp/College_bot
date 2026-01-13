import 'dart:io';
import 'package:excel/excel.dart';

class ExcelParser {
  Future<Excel?> loadExcelFile(String filePath) async {
    try {
      final fileBytes = File(filePath).readAsBytesSync();
      return Excel.decodeBytes(fileBytes);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> parseExcelToMapList(Excel excel) {
    if (excel.tables.isEmpty) {
      return [];
    }

    final table = excel.tables[excel.tables.keys.first]!;
    if (table.rows.isEmpty) {
      return [];
    }

    int headerRowCount = 1;
    if (table.rows.length > 1) {
      final secondRow = table.rows[1];
      bool hasSubHeaders = false;
      for (var cell in secondRow) {
        final value = cell?.value?.toString().trim() ?? '';
        if (value.isNotEmpty && 
            (value.contains('Кол-во') || 
             value.contains('Выдано') || 
             value.contains('Получено') ||
             value.contains('Проверено') ||
             value.contains('План'))) {
          hasSubHeaders = true;
          break;
        }
      }
      if (hasSubHeaders) {
        headerRowCount = 2;
      }
    }

    final headers = <String>[];
    final firstRow = table.rows[0];
    String? currentMainHeader;
    
    for (var j = 0; j < firstRow.length; j++) {
      final firstCell = firstRow[j]?.value?.toString().trim() ?? '';
      String header;
      
      if (headerRowCount == 2 && j < table.rows[1].length) {
        final secondCell = table.rows[1][j]?.value?.toString().trim() ?? '';
        
        if (firstCell.isNotEmpty) {
          currentMainHeader = firstCell;
        }
        
        if (secondCell.isNotEmpty) {
          if (currentMainHeader != null && currentMainHeader.isNotEmpty) {
            header = '$currentMainHeader - $secondCell';
          } else {
            header = secondCell;
          }
        } else if (currentMainHeader != null && currentMainHeader.isNotEmpty) {
          header = currentMainHeader;
        } else {
          header = firstCell.isNotEmpty ? firstCell : 'Column$j';
        }
      } else {
        if (firstCell.isNotEmpty) {
          currentMainHeader = firstCell;
          header = firstCell;
        } else if (currentMainHeader != null && currentMainHeader.isNotEmpty) {
          header = currentMainHeader;
        } else {
          header = 'Column$j';
        }
      }
      
      headers.add(header);
    }

    final data = <Map<String, dynamic>>[];
    for (var i = headerRowCount; i < table.rows.length; i++) {
      final row = table.rows[i];
      final rowData = <String, dynamic>{};

      for (var j = 0; j < headers.length && j < row.length; j++) {
        final cellValue = row[j]?.value;
        rowData[headers[j]] = cellValue;
      }

      if (rowData.values.any((v) => v != null && v.toString().trim().isNotEmpty)) {
        data.add(rowData);
      }
    }

    return data;
  }

  String? getStringValue(dynamic value) {
    if (value == null) return null;
    return value.toString().trim();
  }

  double? getDoubleValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final str = value.toString().trim();
    if (str.isEmpty || str == '-') return null;
    return double.tryParse(str.replaceAll(',', '.'));
  }

  int? getIntValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    final str = value.toString().trim();
    if (str.isEmpty || str == '-') return null;
    return int.tryParse(str);
  }
}
