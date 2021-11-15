import 'dart:io';

import 'package:console_simple/config.dart';
import 'package:console_simple/utils.dart';
import 'package:console_simple/vague_string.dart';

class InputManager {
  List<FileSystemEntity> fseList;
  Map<String, Map<VagueString, String>> rows = {};
  final Config _config;
  VagueString lineKey = VagueString(key: 'line');
  List<String> dups = [];

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
      for (var c in _config.columns) {
        //Vague String overrides == to allow for Strings
        // ignore: unrelated_type_equality_checks
        if (header == c) {
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
      if (pk != "") {
        //If the key exists we have found a dup.
        if (!rows.containsKey(pk)) {
          rows[pk] = row;
        } else {
          Map firstValue = rows[pk]!;
          if (firstValue.isNotEmpty) {
            dups.add(firstValue[lineKey]);
            //Remove line from rows so that it is not added multiple times
            //keep key so odd numbers are still counted as dups
            rows[pk] = {};
          }
          dups.add(line);
        }
      } else {
        log('Row in ${file.path} did not have a ssn:\n $line');
      }
    }
  }
}
