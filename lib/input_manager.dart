import 'dart:io';

import 'package:console_simple/config.dart';
import 'package:console_simple/utils.dart';
import 'package:console_simple/vague_string.dart';

class InputManager {
  List<FileSystemEntity> fseList;
  Map<String, Map<VagueString, Map<VagueString, String>>> rows = {};
  final Config _config;
  VagueString lineKey = VagueString(key: 'line');
  List<String> dups = [];
  List<String> noId = [];
  final defaultTitle = VagueString(key: 'default-garbdge-that-wont-be-a-title');

  InputManager({required this.fseList, required Config config}) : _config = config {
    if (fseList.isEmpty) {
      throw Exception('No input .csv files found');
    }

    for (FileSystemEntity fse in fseList) {
      if (fse.path.contains('.csv')) {
        File file = File(fse.path);
        getInputRows(file);
      } else {
        log('Skipped File:${fse.path}.\n Only uses CSV files.');
      }
    }
    print('Finished gathering input data');
  }

  void getInputRows(File file) {
    Map<VagueString, int> columnIndexs = {};
    List<String> lines = file.readAsLinesSync();

    if (lines.isEmpty) {
      log('File: ${file.path} is empty. Skipped.');
      return;
    }

    List<String> columnHeaders = commaSeparatedSplit(lines.first);
    for (int i = 0; i < columnHeaders.length; i++) {
      var header = columnHeaders[i];
      for (VagueString c in _config.columns) {
        if (c.interpritations.contains(header)) {
          columnIndexs[c] = i;
        }
      }
    }

    for (var c in _config.columns) {
      if (!columnIndexs.containsKey(c)) {
        throw Exception("Column '$c' was not found in File: ${file.path}.");
      }
    }

    lines.removeAt(0);
    for (var line in lines) {
      var rowList = commaSeparatedSplit(line);
      Map<VagueString, String> row = {};
      for (var c in _config.columns) {
        row[c] = rowList[columnIndexs[c]!];
      }
      //Make sure we still have access to the line
      row[lineKey] = line;

      var pk = row[_config.pk]!;
      var titleString = row[_config.title]!;
      if (pk != "") {
        //See if the title exists in titles given. Otherwise use the default title.
        var title = _config.getTitle(titleString) ?? defaultTitle;
        // We need to see if there are any rows that have this id already in our template rows to determine
        // if there is duplicate information that MUST be separated
        Map<VagueString, Map<VagueString, String>>? pkRows = rows[pk];
        if (pkRows == null || pkRows.isEmpty) {
          //No one with this id exists
          setRow(pk, title, row);
        } else {
          Map<VagueString, String> _existingRow = pkRows.values.first;
          if (title == defaultTitle && pkRows.keys.first == defaultTitle) {
            log(
              'ACTION RECOMMENDED: There are two job titles for the same user than are not handled in the config.csv\n'
              ' - TITLES: ${_existingRow[_config.title]} and ${title}'
            );
          }
          if (_existingRow.isNotEmpty) {
            dups.add(_existingRow[lineKey]!);
            //Remove line from rows so that it is not added multiple times
            //keep key so odd numbers are still counted as dups
            setRow(pk, title, {});
          }
          dups.add(line);
        }
      } else {
        log('Row in ${file.path} did not have a ssn:\n $line');
        noId.add(line);
      }
    }
  }

  Map<VagueString, String>? getRow(String pk, VagueString title) {
    Map<VagueString, Map<VagueString, String>>? pkRows = rows[pk];
    if (pkRows != null) {
      Map<VagueString, String>? row = pkRows[title];
      if (row != null) {
        return row;
      }
    }
  }

  void setRow(String pk, VagueString title, Map<VagueString, String> value) {
    rows[pk] = rows[pk] ?? {};
    rows[pk]![title] = value;
  }
}
