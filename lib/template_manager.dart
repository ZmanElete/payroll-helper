import 'dart:io';

import 'vague_string.dart';
import 'config.dart';
import 'utils.dart';

class TemplateManager {
  File file;
  Map<VagueString, int> indexes = {};
  List<String> lines;

  final Config _config;
  TemplateManager(
    this.file, {
    required Config config,
  })  : _config = config,
        lines = file.readAsLinesSync() {
    setIndexes();
  }

  void setIndexes() {
    List<String> headers = commaSeparatedSplit(lines.first);
    for (int i = 0; i < headers.length; i++) {
      var header = headers[i];
      // ignored because VagueString overrides == to allow String comparison
      // ignore: iterable_contains_unrelated_type
      for (var c in _config.columns) {
        //Vague String overrides == to allow for Strings
        // ignore: unrelated_type_equality_checks
        if (header == c) {
          indexes[c] = i;
        }
      }
    }

    for (var c in _config.columns) {
      if (!indexes.containsKey(c)) {
        throw Exception('Column $c missing from template');
      }
    }
  }

  String getColumn(VagueString key, List<String> row) {
    return row[indexes[key]!];
  }

  String replaceColumns(List<String> row, Map<VagueString, String> inputRow) {
    List<ColumnName> columns = [
      ColumnName.regularHours,
      ColumnName.overtimeHours,
      ColumnName.paycheckTips,
    ];
    String title = templateRow[templateColumnIndexes['title']!];
    if (config.titleOptions[TitleOption.skip]!.contains(title)) {
      return joinOnComma(templateRow);
    } else if (config.titleOptions[TitleOption.tipsOnly]!.contains(title)) {
      columns = [
        ColumnName.paycheckTips,
      ];
    }

    for (ColumnName c in columns) {
      String columnString = columnToString(c);
      int templateColumnIndex = templateColumnIndexes[columnString]!;
      var currentValue = templateRow[templateColumnIndex];
      var newValue = inputRow[c]!;

      bool replace = true;
      if (currentValue.isNotEmpty) {
        log(
          'The column for the user with title: "$title" and ssn: "${inputRow[PK]}" already has data in it:\n'
          'data: $currentValue\n'
          'Should we replace $currentValue with $newValue\n'
          'Type "y" for yes or anything else for no',
        );
        var response = stdin.readLineSync(encoding: utf8) ?? '';
        replace = response.toLowerCase() == 'y';
      }

      if (replace) {
        templateRow[templateColumnIndex] = newValue;
      }
    }

    return joinOnComma(templateRow);
  }
}
