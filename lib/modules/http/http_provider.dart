import 'package:maxilozoz_box/application.dart';
import 'package:maxilozoz_box/modules/http/http.dart';
import 'package:maxilozoz_box/modules/http/log.dart' as HttpLog;
import 'package:maxilozoz_box/modules/http/rap.dart';
import 'package:dio/dio.dart';

class HttpProvider {
  String get name {
    return 'http';
  }

  void register(Application app){
    app.bind('http', (Application app, dynamic params) {
      BaseOptions options = new BaseOptions();

      options.baseUrl = app.config('http_base_url') ?? '';
      options.connectTimeout = app.config('http_connect_timeout') ?? 10000;
      options.receiveTimeout = app.config('http_receive_timeout') ?? 10000;

      Http http = new Http(options);

      http.logEngine = app.make('log');

      if(app.config('http_use_rap') ?? false) {
        http.interceptors.add(Rap.getDioWrapper());
      }

      if(app.config('http_use_log') ?? false) {
        http.interceptors.add(HttpLog.Log.getDioWrapper());
      }
      return Http(options);
    }, share: false);
  }

  void boot(Application app){}
}