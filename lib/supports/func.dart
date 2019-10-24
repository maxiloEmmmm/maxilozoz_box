import 'package:maxilozoz_box/application.dart';

dynamic appMake({bool force: false, String key: ''}){
  if(Application.instance == null) {
    print('[warn] maxilozoz support func: application not init.');
    return null;
  }

  return key.isEmpty ? Application.instance : Application.instance.make(key);
}

dynamic appConfig(dynamic model, {dev: false}){
  if(Application.instance == null) {
    print('[warn] maxilozoz support func: application not init.');
    return null;
  }

  return Application.instance.config(model, dev: dev);
}