import 'package:maxilozoz_box/application.dart';

class ServiceProvider {
  bool booted = false;

  Map providers = {};

  Application app;

  ServiceProvider({this.app});

  void register(dynamic provider) {
    if(this.providers.containsKey(provider.name)) {
      print('[warn]maxilozoz box: provider register exist: ' + provider.name);
      return ;
    }

    this.providers[provider.name] = provider;
    
    provider.register(this.app);

    if (this.booted) {
      provider.boot(this.app);
    }
  }

  void run(){
    if(this.booted) {return ;}

    this.providers.forEach((k, v) => v.boot(this.app));

    this.booted = true;
  }
}