import 'package:dio/dio.dart';
import 'package:maxilozoz_box/modules/http/rap_utils.dart';

class Rap {
  static InterceptorsWrapper getDioWrapper() {
    return InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
      RapUtils rap = new RapUtils();
      var proxy = rap.tryProxy(options.path, options.method);
      if (proxy != false) {
        return handler.resolve(Response(
            data: proxy,
            headers: new Headers(),
            isRedirect: false,
            requestOptions: options,
            statusCode: 200,
            statusMessage: 'OK'));
      } else {
        return handler.next(options);
      }
    });
  }
}
