import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:maxilozoz_box/modules/route/route.dart';
import 'package:maxilozoz_box/modules/route/routeMiddleware.dart';

void main() {
  test('route match', () {
    MinRoute route = new MinRoute();

    route.add('/a/b', () {});
    route.add('/a/:c/b', () {});
    route.add('/a/:c/b/:q', () {});

    var match = route.match('/a/');
    expect(match == null, true);

    match = route.match('/a/b');
    expect(match != null, true);

    match = route.match('/a/5/b');
    expect(match != null, true);
    expect(match.params['c'], '5');

    match = route.match('/a/5/b/1');
    expect(match != null, true);
    expect(match.params['q'], '1');

    match = route.match('/a/5/b/-');
    expect(match == null, true);
  });

  test('route middleware match', () {
    MinRoute route = new MinRoute();

    route.add('/q', () {}, middlewares: ['auth']);
    route.routeMiddleware.add('auth', TestMiddleware());
    var match = route.match('/q');
    expect(match.middlewares, ['auth'], reason: '路由中间件个数内容不符合');

    RouteSettings settings = route.routeMiddleware
        .filter(RouteSettings(name: '/q'), match.middlewares)!;
    expect(settings.name, '/auth/login', reason: '路由中间件未生效');
  });
}

class TestMiddleware {
  RouteMiddlewareFilterItem filter(RouteSettings settings) {
    RouteMiddlewareFilterItem item =
        RouteMiddlewareFilterItem(ok: true, settings: settings);
    // auth is false, to auth
    bool auth = false;
    if (!auth) {
      item.settings = settings.copyWith(name: '/auth/login');
      item.ok = false;
    }
    return item;
  }
}
