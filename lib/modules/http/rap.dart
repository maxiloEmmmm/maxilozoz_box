import 'package:dio/dio.dart';
import 'package:maxilozoz_box/modules/http/rap_utils.dart';

class Rap {
  static InterceptorsWrapper getDioWrapper(){
    return InterceptorsWrapper(onRequest: (RequestOptions options) {
      RapUtils rap = new RapUtils();
      var proxy = rap.tryProxy(options.path, options.method);
      if(proxy != false) {
        return new Response(data: proxy, headers: new Headers(), request: null, isRedirect: false, statusCode: 200, statusMessage: 'OK');
      }else {
        return options;
      }
    });
  }
}