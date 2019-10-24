import 'package:dio/dio.dart';

class Log {
  static InterceptorsWrapper getDioWrapper(){
    return InterceptorsWrapper(onResponse: (Response response){
      print("Response: " + response.request.path);
      print("----------------------------------");
      print("|    request: ");
      print("|        query params: ");
      print("|            " + response.request.queryParameters.toString());
      if(response.request.method.toLowerCase() == 'post') {
        print("|        post params: ");
        print("|            " + response.request.data.toString());
      }
      print("| status: " + response.statusCode.toString());
      print("| data: " + response.data.toString());
    });
  }
}