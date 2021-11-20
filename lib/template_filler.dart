import 'dart:convert';
import 'dart:io';

import 'package:console_simple/vague_string.dart';

import 'input_manager.dart';
import 'template_manager.dart';
import 'utils.dart';
import 'config.dart';

class TemplateFiller {
  Config config;
  Directory inputDir;
  Directory outputDir;
  File templateFile;

  TemplateFiller._({
    required this.config,
    required this.templateFile,
    required this.inputDir,
    required this.outputDir,
  });

  factory TemplateFiller({
    required String configPath,
    required String templateDirPath,
    required String inputDirPath,
    required String outputDirPath,
  }) {
    String curr = Directory.current.path;
    File configFile = File(curr + configPath);
    Config config = Config(configFile);
    Directory inputDir = Directory(curr + inputDirPath)..createSync();
    Directory outputDir = Directory(curr + outputDirPath)..createSync();
    Directory templateDir = Directory(curr + templateDirPath)..createSync();
    File template = getTemplateFile(templateDir);
    log('Template Found');
    return TemplateFiller._(
      config: config,
      templateFile: template,
      inputDir: inputDir,
      outputDir: outputDir,
    );
  }

  static File getTemplateFile(Directory dir) {
    var fileList = dir.listSync().where((file) => file.path.contains('.csv'));
    if (fileList.isEmpty) {
      throw Exception('No template found.\n'
          'Please put a .csv template here\n${dir.path}\n');
    }

    if (fileList.length > 1) {
      throw Exception(
        'Multiple template .csv files found. IDK which to use.\n'
        'Please make sure there is only 1 .csv file in the ${dir.path} folder',
      );
    }

    return File((fileList.first).path);
  }

  /// List of inputLines with no match in template
  List<String> notFoundInTemplate = [];
  Set<String> noTitleIdSet = {};

  void run() {
    var inputFileEntities = inputDir.listSync().where((file) => file.path.contains('.csv'));
    var input = InputManager(
      fseList: inputFileEntities.toList(),
      config: config,
    );

    var template = TemplateManager(templateFile, config: config);

    List<String> outputLines = [];
    for (String line in template.lines) {
      var row = commaSeparatedSplit(line);
      String pk = template.getColumn(config.pk, row);
      String titleString = template.getColumn(config.title, row);

      VagueString title = input.defaultTitle;
      // Vague string overridden == so .contains works on strings
      // ignore: iterable_contains_unrelated_type
      if (config.titles.contains(titleString)) {
        title = config.titles.firstWhere((t) => t.interpritations.contains(titleString));
      } else if (noTitleIdSet.contains(pk)) {
        log('ACTION REQUIRED: There is a repeat in ssn in this template file. To differenciate them\n'
            'atleast one of the users titles should be put into the config.csv file\n'
            'For this to work, the title from the template and the title from the input file should both be put in the same row\n'
            ' - SSN: $pk | ONE OF THE TITLES: $titleString');
      } else {
        noTitleIdSet.add(pk);
      }

      Map<VagueString, String>? inputRow = input.getRow(pk, title);
      if (inputRow != null && inputRow.isNotEmpty) {
        outputLines.add(template.replaceColumns(row, inputRow));
        // Vague string overridden == so .contains works on strings
        // ignore: unrelated_type_equality_checks
        input.rows.removeWhere((key, value) => key == pk && value == title);
      } else {
        outputLines.add(line);
        if (line != template.lines.first) {
          log('Skipped Line in Template:  $line');
        }
      }
    }

    DateTime now = DateTime.now();
    String s = Config.slash;
    var newOutputDir = Directory(
      outputDir.path + '$s${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}',
    )..createSync();
    File output = File(newOutputDir.path + '${s}upload.csv');
    output.writeAsStringSync(outputLines.join('\n') + '\n');
    if (input.dups.isNotEmpty) {
      File duplicates = File(newOutputDir.path + '${s}duplicates.csv');
      duplicates.writeAsStringSync(input.dups.join('\n') + '\n');
    }

    for (var titleRow in input.rows.values) {
      for (var row in titleRow.values) {
        notFoundInTemplate.add(row[input.lineKey] ?? '');
      }
    }
    if (notFoundInTemplate.isNotEmpty) {
      File notFound = File(newOutputDir.path + '${s}not-found.csv');
      notFound.writeAsStringSync(notFoundInTemplate.join('\n') + '\n');
    }
    print('Completed Press Enter to contine...');
    stdin.readLineSync(encoding: utf8);
  }
}
