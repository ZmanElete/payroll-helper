import 'dart:convert';
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
      for (VagueString c in _config.columns) {
        if (c.interpritations.contains(header)) {
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
    assert(_config.columns.contains(key));
    return row[indexes[key]!];
  }

  String replaceColumns(List<String> row, Map<VagueString, String> inputRow) {
    List<VagueString> replaceColumns = _config.columns.where((c) => c != _config.pk && c != _config.title).toList();
    String title = getColumn(_config.title, row);
    var skipTitles = _config.titleOptions.where((to) => to.key == 'skip_titles');
    var onlyTipsTitles = _config.titleOptions.where((to) => to.key == 'tips_only_titles');
    if (skipTitles.isNotEmpty && skipTitles.first.interpritations.contains(title)) {
      return joinOnComma(row);
    } else if (onlyTipsTitles.isNotEmpty && onlyTipsTitles.first.interpritations.contains(title)) {
      replaceColumns = [
        _config.columns.firstWhere((to) => to.interpritations.contains('paycheck_tips')),
      ];
    }

    for (VagueString key in replaceColumns) {
      int templateColumnIndex = indexes[key]!;
      var currentValue = row[templateColumnIndex];
      var newValue = inputRow[key]!;

      bool replace = true;
      if (currentValue.isNotEmpty) {
        log(
          'The column for the user with title: "$title" and ssn: "${inputRow[_config.pk]}" already has data in it:\n'
          'current data: $currentValue\n'
          'new data: $newValue\n'
          'Should we replace $currentValue with $newValue\n'
          'Type "y" for yes or anything else for no',
        );
        var response = stdin.readLineSync(encoding: utf8) ?? '';
        replace = response.toLowerCase() == 'y';
      }

      if (replace) {
        row[templateColumnIndex] = newValue;
      }
    }

    return joinOnComma(row);
  }
}
