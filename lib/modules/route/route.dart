import 'package:flutter/material.dart';
import 'package:maxilozoz_box/modules/route/routeMiddleware.dart';
import './404.dart';

class MinRoute {
  List routes = [];

  static BuildContext? routeContext;

  RouteMiddleware routeMiddleware = RouteMiddleware();

  MinRouteGroupModel group =
      MinRouteGroupModel(using: false, pre: '', middlewares: []);

  Route<dynamic> generate(RouteSettings settings) {
    var route = this.match(settings.name);

    if (route != null) {
      RouteSettings _settings =
          routeMiddleware.filter(settings.copyWith(), route.middlewares)!;

      if (_settings.name == settings.name) {
        Widget? widget;

        try {
          if (route.hasParam) {
            widget = route.handler(route.params);
          } else {
            widget = route.handler();
          }
        } catch (e) {
          //todo: err page
          print(
              "[todo] maxilozoz route: param function or no param function not exist.");
        }

        return MaterialPageRoute(
            builder: (BuildContext context) {
              routeContext = context;
              return widget!;
            }, settings: settings);
      } else {
        settings = _settings;
      }
    }

    late WidgetBuilder widgetBuilder =
        // todo: 404 page option
        (BuildContext context) => NotFoundRoute();
    switch (settings.name) {
      case '/404':
      default:
        {
          //widgetBuilder = (BuildContext _) => I404Page();
        }
    }
    return MaterialPageRoute(builder: (BuildContext context) {
      routeContext = context;
      return widgetBuilder(context);
    }, settings: settings);
  }

  bool addGroup(List middlewares, String pre, Function make) {
    this.group.using = true;

    if (pre.endsWith('/')) {
      pre = pre.substring(0, pre.length - 1);
    }

    this.group.pre = pre;

    if (middlewares.isNotEmpty) {
      this.group.middlewares = middlewares;
    }

    make();

    this.group.middlewares = [];
    this.group.using = false;

    return true;
  }

  bool add(String path, Function make, {List? middlewares}) {
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    if (!path.startsWith('/')) {
      path = '/' + path;
    }

    if (this.group.using!) {
      path = this.group.pre! + path;

      if (this.group.middlewares!.length > 0) {
        middlewares =
            ((middlewares ?? []) + this.group.middlewares!).toSet().toList();
      }
    }

    middlewares = middlewares ?? [];

    RegExp reg = new RegExp('\/((:)*[a-zA-Z_][a-zA-Z_0-9]*)*');
    Iterable<Match> matches = reg.allMatches(path);
    if (matches.isEmpty) {
      print('maxilozoz box err: route add path is invaild.');
      return false;
    }

    this.routes.add(MinRouteItem(
        path: path.replaceAll(new RegExp(':[^/]+'), '([a-zA-Z0-9_]+)'),
        handler: make,
        matches: matches,
        hasParam: (new RegExp('/:')).hasMatch(path),
        middlewares: middlewares));
    return true;
  }

  dynamic match(path) {
    if (path.endsWith('/') && path != '/') {
      path = path.substring(0, path.length - 1);
    }

    int len = this.routes.length;

    for (int i = 0; i < len; i++) {
      RegExp reg = new RegExp('^' + this.routes[i].path + '\$');
      if (reg.hasMatch(path)) {
        List<Match> paramMatches = reg.allMatches(path).toList();
        List<Match> matches = this.routes[i].matches.toList();
        Map params = {};

        int mLen = matches.length;
        int basic = 1;
        for (int j = 0; j < mLen; j++) {
          Match match = matches[j];

          if (match.groupCount == 2 &&  match.group(1) != null && match.group(1)!.startsWith(':')) {
            String k = match.group(1)!.substring(1);
            params[k] = paramMatches[0].group(basic++);
          }
        }
        this.routes[i].params = params;
        return this.routes[i];
      } else {
        continue;
      }
    }
    return null;
  }
}

class MinRouteItem {
  String? path;

  Function? handler;

  Iterable<Match>? matches;

  Map params = {};

  List? middlewares = [];

  bool? hasParam = false;

  MinRouteItem(
      {this.path, this.handler, this.matches, this.middlewares, this.hasParam});
}

class MinRouteGroupModel {
  bool? using = false;

  String? pre = '';

  List? middlewares = [];

  MinRouteGroupModel({this.using, this.pre, this.middlewares});
}
