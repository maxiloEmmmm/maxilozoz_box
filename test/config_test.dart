import 'package:flutter_test/flutter_test.dart';
import 'package:maxilozoz_box/modules/config/config.dart';

void main() {
  test('adds one to input values', () {
    Config config = new Config();
    //test debug model is prod.

    config.add({
      "a": 1
    });

    config.add({
      "b": 1
    }, inDev: true);

    expect(config.get("a"), 1);
    expect(config.get("b") == null, true);
  });
}
