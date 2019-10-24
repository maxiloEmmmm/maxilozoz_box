import 'package:maxilozoz_box/application.dart';
import 'package:maxilozoz_box/modules/config/config.dart';

class ConfigProvider {
  String get name {
    return 'config';
  }

  void register(Application app){
    app.bind('config', (Application app, dynamic params) {
      return Config();
    });
  }

  void boot(Application app){}
}