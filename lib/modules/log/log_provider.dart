import 'package:maxilozoz_box/application.dart';
import 'package:maxilozoz_box/modules/log/log.dart';

class LogProvider {
  String get name {
    return 'log';
  }

  void register(Application app){
    app.bind('log', (Application app, dynamic params) {
      return Log();
    });
  }

  void boot(Application app){}
}