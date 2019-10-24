import 'package:maxilozoz_box/application.dart';
import 'package:maxilozoz_box/modules/route/route.dart';

class RouteProvider {
  String get name {
    return 'route';
  }

  void register(Application app){
    app.bind('route', (Application app, dynamic params) {
      return MinRoute();
    });
  }

  void boot(Application app){}
}