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
  List<VagueString> titles = [];

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
          } else {
            titles.add(entry);
          }
        }
      }
    }
    _checkForKeyExistence();
  }

  VagueString? getTitle(String string) {
    var matches = titles.where(
      (t) => t.interpritations.contains(string),
    );
    if (matches.isNotEmpty) {
      return matches.first;
    }
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
    for (var to in titleOptionsKeys) {
      // ignored because VagueString overrides == to allow String comparison
      // ignore: iterable_contains_unrelated_type
      if (!titleOptions.contains(to)) {
        String message = "No values for $to found in config";
        log(message);
      }
    }
  }
}
