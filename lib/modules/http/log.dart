import 'package:dio/dio.dart';

class Log {
  static InterceptorsWrapper getDioWrapper() {
    return InterceptorsWrapper(
        onResponse: (Response response, ResponseInterceptorHandler handler) {
      print("Response: " + response.requestOptions.path);
      print("----------------------------------");
      print("|    request: ");
      print("|        query params: ");
      print(
          "|            " + response.requestOptions.queryParameters.toString());
      if (response.requestOptions.method.toLowerCase() == 'post') {
        print("|        post params: ");
        print("|            " + response.requestOptions.data.toString());
      }
      print("| status: " + response.statusCode.toString());
      print("| data: " + response.data.toString());
      handler.next(response);
    });
  }
}
