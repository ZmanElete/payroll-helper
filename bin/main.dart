import 'package:console_simple/template_filler.dart';
import 'package:console_simple/utils.dart';

void main(List<String> arguments) async {
  rotateLogs();
  try {
    var templateFiller = TemplateFiller(
      configPath: '\\config.txt',
      templateDirPath: '\\template',
      outputDirPath: '\\output',
      inputDirPath: '\\input',
    );
    templateFiller.run();
  } catch (e) {
    errorMessage(e.toString());
  }
}
