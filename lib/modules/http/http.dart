import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';
import 'package:flutter/cupertino.dart';
import 'package:maxilozoz_box/modules/log/log.dart';

class Http extends DioForNative {
  Http([BaseOptions options]):super(options);

  BuildContext context;

  Log logEngine;

  final int httpRewriteCode = 801;

  final String httpErrLogKey = '_http_err_log_';

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic> queryParameters, Options options, CancelToken cancelToken, onReceiveProgress}) {
    Future<Response<T>> tmp = super.get(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);
    tmp.then(this.rewriteHandler)
      .catchError(this.errorHandler);
    return tmp;
  }

  @override
  Future<Response<T>> post<T>(String path, {data, Map<String, dynamic> queryParameters, Options options, CancelToken cancelToken, onSendProgress, onReceiveProgress}) {
    Future<Response<T>> tmp = super.post(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken, onSendProgress: onSendProgress, onReceiveProgress: onReceiveProgress);
    tmp.then(this.rewriteHandler)
      .catchError(this.errorHandler);
    return tmp;
  }

  void rewriteHandler(Response response){
    if(response.statusCode == this.httpRewriteCode) {
      if(this.context == null) {
        print('[warn] maxilozoz http: rewrite mode without context[BuildContext], please set context to http');
        return;
      }
      Navigator.pushReplacementNamed(this.context, response.statusMessage);
    }
  }

  void errorHandler(e) async {
    logEngine.set(this.httpErrLogKey, e.toString());
  }

  Future<List<String>> getErrorLog() async {
    return logEngine.get(this.httpErrLogKey);
  }
}