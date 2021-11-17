import 'package:console_simple/config.dart';
import 'package:console_simple/template_filler.dart';
import 'package:console_simple/utils.dart';

void main(List<String> arguments) async {
  rotateLogs();
  String s = Config.slash;
  try {
    var templateFiller = TemplateFiller(
      configPath: '${s}config.csv',
      templateDirPath: '${s}template',
      outputDirPath: '${s}output',
      inputDirPath: '${s}input',
    );
    templateFiller.run();
  } catch (e) {
    errorMessage(e.toString());
  }
}
