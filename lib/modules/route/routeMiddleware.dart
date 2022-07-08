import 'package:flutter/material.dart';

class RouteMiddleware {
  Map middlewares = {};

  RouteSettings? filter(RouteSettings settings, List checkMiddlewares) {
    RouteMiddlewareFilterItem? item = RouteMiddlewareFilterItem(ok: true, settings: settings);
    checkMiddlewares.any((val) {
      if(!this.middlewares.containsKey(val)) {
        print('[warn] maxilozoz route middleware: $val middleware not exist, nothing to do~');
        return false;
      }

      item = this.middlewares[val].filter(settings);

      return !item!.ok!;
    });

    return item!.settings;
  }

  void add(k, v){
    if(this.middlewares.containsKey(k)) {
      print('[warn] maxilozoz route middleware: add exist: ' + k);
      return;
    }

    this.middlewares[k] = v;
  }
}

class RouteMiddlewareFilterItem {
  bool? ok;

  RouteSettings? settings;

  RouteMiddlewareFilterItem({this.ok, this.settings});
}