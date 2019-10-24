import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maxilozoz_box/modules/http/http.dart';

void main() {
  test('adds one to input values', () async {
    Http http = new Http();
    Response response = await http.get('http://www.baidu.com');
    expect(response.statusCode, 200);
  });
}
