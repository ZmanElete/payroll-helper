import 'dart:io';

import 'package:console_simple/vague_string.dart';
import 'package:console_simple/utils.dart';

const List<String> columnKeys = [
  'ssn',
  'regular_hours',
  'overtime_hours',
  'paycheck_tips',
  'title',
];

const List<String> titleOptionsKeys = [
  'skip_titles',
  'tips_only_titles',
];

class Config {
  static String slash = !Platform.isWindows ? '/' : '\\';

  late VagueString pk;
  late VagueString title;
  List<VagueString> columns = [];
  List<VagueString> titleOptions = [];

  List<String> get columnNames => columns.fold([], (v, n) => v + n.interpritations.toList());

  Config(File file) {
    var lines = file.readAsLinesSync();
    for (String s in lines) {
      if (s.isNotEmpty && s[0] != '#') {
        var args = commaSeparatedSplit(s);
        if (args.length > 1) {
          String key = args[0];
          Set<String> interpritations = args.toSet();
          var entry = VagueString(
            key: key,
            interpritations: interpritations,
          );

          if (columnKeys.contains(key)) {
            columns.add(entry);
            if (key == 'ssn') pk = entry;
            if (key == 'title') title = entry;
          } else if (titleOptionsKeys.contains(key)) {
            titleOptions.add(entry);
          }
        }
      }
    }
    _checkForKeyExistence();
  }

  void _checkForKeyExistence() {
    for (var c in columnKeys) {
      // ignored because VagueString overrides == to allow String comparison
      // ignore: iterable_contains_unrelated_type
      if (!columns.contains(c)) {
        String message = "No values for $c found in config";
        throw Exception(message);
      }
    }
  }
}
