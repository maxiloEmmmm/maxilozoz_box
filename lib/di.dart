import 'package:maxilozoz_box/application.dart';

class DI {
  Map _binds = {};

  Application? app;

  DI({this.app});

  void bind(String key, Function(DI app, dynamic params) instance, {bool share = true}) {
    this._binds[key] = new Bind(key: key, instance: instance, share: share);
  }

  dynamic make(String key, {dynamic params, force: false}) {
    return this._binds[key].make(this, params, force: force);
  }
}

class Bind {
  bool? share;

  Function(DI app, dynamic params)? instance;

  dynamic _instance;

  String? key;

  Bind({this.key, this.instance, this.share});

  dynamic make(DI app, dynamic params, {force: false}){
    if(this.share! && this._instance != null && !force) {
      return this._instance;
    }

    this._instance = this.instance!(app, params);
    return this._instance;
  }
}