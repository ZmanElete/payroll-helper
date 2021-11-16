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
      String title = template.getColumn(config.title, row);
      var rows = input.rows[pk]!;
      Map<VagueString, String>? inputRow;
      for (var key in rows.keys) {
        if (key.interpritations.contains(title)) {
          inputRow = rows[key];
        }
      }
      if (inputRow != null) {
        outputLines.add(template.replaceColumns(row, inputRow));
      } else {
        outputLines.add(line);
        if (line != template.lines.first) {
          log('Skipped:\n $line');
        }
      }
    }

    DateTime now = DateTime.now();
    var newOutputDir = Directory(
      outputDir.path + '\\${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}',
    )..createSync();
    File output = File(newOutputDir.path + '\\upload.csv');
    output.writeAsStringSync(outputLines.join('\n') + '\n');
    if (input.dups.isNotEmpty) {
      File duplicates = File(newOutputDir.path + '\\duplicates.csv');
      duplicates.writeAsStringSync(input.dups.join('\n') + '\n');
    }
    // if (notFoundInTemplate.isNotEmpty) {
    //   File notFound = File(newOutputDir.path + '\\not-found.csv');
    //   notFound.writeAsStringSync(notFoundInTemplate.join('\n') + '\n');
    // }
    print('Completed Press Enter to contine...');
    stdin.readLineSync(encoding: utf8);
  }
}
