import 'package:flutter_test/flutter_test.dart';

import 'package:maxilozoz_box/di.dart';
import 'dart:math';

void main() {
  test('adds one to input values', () {
    final container = DI();
    container.bind('s1', (DI app, dynamic params){
      return "s1 maked"  + Random().nextInt(100).toString();
    });

    container.bind('s2', (DI app, dynamic params){
      return "s2 maked" + Random().nextInt(100).toString();
    }, share: false);

    expect(container.make('s1'), container.make('s1'));
    expect(container.make('s2') != container.make('s2'), true);
  });
}
