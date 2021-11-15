import 'dart:io';
import 'dart:convert';

void errorMessage(String message) {
  log('');
  log(message);
  log('Enter to continue...');
  stdin.readLineSync(encoding: utf8);
  exit(-1);
}

var now = DateTime.now();
var logFile = File(
  Directory.current.path +
      "\\logs\\${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}.${now.millisecond}-log.txt",
)..createSync();

void log(String message) {
  logFile.writeAsStringSync(message + '\n', mode: FileMode.append);
  print(message);
}

void rotateLogs() {
  var logDir = Directory(Directory.current.path + "\\logs")..createSync();
  var files = logDir.listSync();
  if (files.length > 5) {
    files.sort((fse1, fse2) => fse1.path.compareTo(fse2.path));
    var fso = files.first;
    var file = File(fso.path);
    file.deleteSync();
  }
}

List<String> commaSeparatedSplit(String line) {
  const replaceChar = '#|%|#';
  //Removed commas that exist in the column (not delimeters)
  var strippedCommas = line.replaceAllMapped(
    RegExp("\"(.*),(.*)\""),
    (m) => '${m[1]}$replaceChar${m[2]}',
  );
  var cleaned = strippedCommas.replaceAll('"', '');
  List<String> splitOnComma = cleaned.split(',');
  for (int i = 0; i < splitOnComma.length; i++) {
    splitOnComma[i] = splitOnComma[i].replaceAll(replaceChar, ',');
  }
  return splitOnComma;
}

String joinOnComma(List<String> list) {
  for (int i = 0; i < list.length; i++) {
    var str = list[i];
    if (str.contains(',')) {
      list[i] = '"' + str + '"';
    }
  }
  return list.join(',');
}
