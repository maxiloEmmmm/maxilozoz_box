import 'dart:convert';

import 'package:maxilozoz_box/service_provider.dart';
import 'package:maxilozoz_box/di.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:maxilozoz_box/modules/route/route_provider.dart';
import 'package:maxilozoz_box/modules/config/config_provider.dart';
import 'package:maxilozoz_box/modules/http/http_provider.dart';
import 'package:maxilozoz_box/modules/log/log_provider.dart';

class Application {
  late ServiceProvider serviceProvider;
  late DI di;
  static Application? instance;
  String errorLogKey = '_app_err_log_';

  Application() {
    instance = this;
    serviceProvider = new ServiceProvider();
    di = new DI();
    di.app = this;
    serviceProvider.app = this;

    this.initBaseProvider();
  }

  void initBaseProvider() {
    this.serviceProvider.register(ConfigProvider());
    this.serviceProvider.register(RouteProvider());
    this.serviceProvider.register(HttpProvider());
    this.serviceProvider.register(LogProvider());
  }

  void register(dynamic provider) {
    this.serviceProvider.register(provider);
  }

  void routeMiddleware(String k, dynamic v) {
    this.di.make('route').routeMiddleware.add(k, v);
  }

  dynamic make(String key, {params, force: false}) {
    return this.di.make(key, force: force, params: params);
  }

  dynamic bind(String key, Function(Application app, dynamic params) instance,
      {bool share = true}) {
    this.di.bind(key, (DI di, dynamic params) {
      return instance(this, params);
    }, share: share);
  }

  dynamic config(dynamic model, {dev: false}) {
    if (model is String) {
      return this.di.make('config').get(model);
    } else {
      if (model is! Map) {
        print("[warn] maxilozoz box: add config params is not `Map`");
      } else {
        this.di.make('config').add(model, inDev: dev);
      }
      return null;
    }
  }

  dynamic log({String key: '', String logStr: '', int limit: 200}) {
    key = key.isEmpty ? this.errorLogKey : key;
    if (logStr.isEmpty) {
      return this.di.make('log').get(key);
    } else {
      return this.di.make('log').set(logStr, key, limit: limit);
    }
  }

  void run() {
    runZonedGuarded(() {
      ErrorWidget.builder = (FlutterErrorDetails details) {
        Zone.current.handleUncaughtError(details.exception, details.stack!);
        return Container(color: Colors.transparent);
      };
      this.serviceProvider.run();
      runApp(_App(app: this));
    }, (Object obj, StackTrace stack) {
      this.di.make('log').set(
          jsonEncode({'obj': obj.toString(), 'stack': stack.toString()}),
          this.errorLogKey);
      print(obj);
      print(stack);
    });
  }
}

class _App extends StatelessWidget {
  final Application? app;

  _App({this.app});

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        initialRoute: '/',
        onGenerateRoute: this.app!.make('route').generate,
        theme: ThemeData(
          primarySwatch: Colors.green,
          backgroundColor: Colors.grey,
        ));
  }
}
